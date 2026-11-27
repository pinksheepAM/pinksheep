"""Qui réfléchit : le modèle local (Ollama) par défaut, une IA en ligne en option.

Réglages : ~/.config/pinksheep/ia.json (jamais de clé dedans) :
  {"mode": "local" | "en_ligne" | "mixte",
   "modele_local": "qwen2.5:3b",              (sinon : celui choisi à l'installation)
   "en_ligne": {"type": "claude" | "openai", "modele": "...", "url": "..."}}
La clé d'API est rangée dans le trousseau du système (libsecret, via secret-tool),
jamais dans un fichier.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

OLLAMA = os.environ.get("PINKSHEEP_IA_OLLAMA", "http://127.0.0.1:11434")
PROFIL_SYSTEME = Path("/etc/pinksheep/ia.json")


class Indisponible(Exception):
    """Le fournisseur ne répond pas (pas installé, modèle pas encore téléchargé, pas de clé…)."""


def fichier_reglages() -> Path:
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "pinksheep" / "ia.json"


def reglages() -> dict:
    defaut = {"mode": "local", "modele_local": None, "en_ligne": {"type": "claude", "modele": "claude-haiku-5-5"}}
    try:
        defaut.update(json.loads(fichier_reglages().read_text()))
    except (OSError, ValueError):
        pass
    if not defaut.get("modele_local"):
        try:
            defaut["modele_local"] = json.loads(PROFIL_SYSTEME.read_text()).get("modele")
        except (OSError, ValueError):
            pass
    return defaut


def enregistrer_reglages(r: dict) -> None:
    propre = {k: v for k, v in r.items() if "cle" not in k.lower() and "key" not in k.lower()}
    f = fichier_reglages()
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(json.dumps(propre, ensure_ascii=False, indent=2))


# ── Trousseau ──────────────────────────────────────────────────
def _attributs(fournisseur: str) -> list[str]:
    return ["service", "pinksheep-ia", "fournisseur", fournisseur]


def ranger_cle(fournisseur: str, cle: str) -> None:
    """Range la clé dans le trousseau. Elle passe par l'entrée standard, jamais en argument."""
    if shutil.which("secret-tool") is None:
        raise Indisponible("secret-tool manque (paquet libsecret).")
    r = subprocess.run(["secret-tool", "store", "--label", f"PinkSheep IA ({fournisseur})",
                        *_attributs(fournisseur)], input=cle, text=True, capture_output=True, timeout=60)
    if r.returncode != 0:
        raise Indisponible("Le trousseau a refusé la clé : " + (r.stderr.strip() or "erreur inconnue"))


def lire_cle(fournisseur: str) -> str | None:
    if shutil.which("secret-tool") is None:
        return None
    r = subprocess.run(["secret-tool", "lookup", *_attributs(fournisseur)],
                       capture_output=True, text=True, timeout=30)
    return r.stdout.strip() or None if r.returncode == 0 else None


def oublier_cle(fournisseur: str) -> None:
    if shutil.which("secret-tool"):
        subprocess.run(["secret-tool", "clear", *_attributs(fournisseur)], capture_output=True, timeout=30)


# ── Appels ─────────────────────────────────────────────────────
def _post(url: str, donnees: dict, entetes: dict, delai: float) -> dict:
    req = urllib.request.Request(url, data=json.dumps(donnees).encode(), method="POST",
                                 headers={"Content-Type": "application/json", **entetes})
    try:
        with urllib.request.urlopen(req, timeout=delai) as rep:
            return json.loads(rep.read())
    except urllib.error.HTTPError as e:
        corps = e.read().decode(errors="ignore")[:300]
        raise Indisponible(f"Erreur {e.code} : {corps}") from None
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise Indisponible(f"Pas de réponse ({e}).") from None


def local(systeme: str, messages: list[dict], modele: str | None) -> str:
    if not modele:
        raise Indisponible("Aucun modèle local choisi (assistant désactivé sur ce PC ?).")
    rep = _post(f"{OLLAMA}/api/chat", {
        "model": modele, "stream": False, "format": "json",
        "options": {"temperature": 0.2},
        "messages": [{"role": "system", "content": systeme}, *messages],
    }, {}, delai=120)
    if "error" in rep:
        raise Indisponible(rep["error"])
    return rep.get("message", {}).get("content", "")


def en_ligne(systeme: str, messages: list[dict], conf: dict) -> str:
    type_ = conf.get("type", "claude")
    cle = lire_cle(type_)
    if not cle:
        raise Indisponible(f"Pas de clé {type_} dans le trousseau (pinksheep-ia --cle {type_}).")
    if type_ == "claude":
        rep = _post(conf.get("url", "https://api.anthropic.com/v1/messages"), {
            "model": conf.get("modele", "claude-haiku-5-5"), "max_tokens": 600,
            "system": systeme, "messages": messages,
        }, {"x-api-key": cle, "anthropic-version": "2023-06-01"}, delai=60)
        return "".join(b.get("text", "") for b in rep.get("content", []) if b.get("type") == "text")
    # Tout service compatible OpenAI (Mistral, Groq, OpenRouter…)
    rep = _post(conf.get("url", "https://api.openai.com/v1/chat/completions"), {
        "model": conf.get("modele", ""), "response_format": {"type": "json_object"},
        "messages": [{"role": "system", "content": systeme}, *messages],
    }, {"Authorization": f"Bearer {cle}"}, delai=60)
    return rep["choices"][0]["message"]["content"]


def etat_ollama(modele: str | None) -> str:
    """« pret », « telechargement », « absent » ou « eteint »."""
    try:
        with urllib.request.urlopen(f"{OLLAMA}/api/tags", timeout=3) as rep:
            noms = {m.get("name") for m in json.loads(rep.read()).get("models", [])}
    except (urllib.error.URLError, OSError, ValueError):
        return "eteint"
    if modele and (modele in noms or f"{modele}:latest" in noms):
        return "pret"
    return "absent"
