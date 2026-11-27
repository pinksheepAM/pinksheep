"""pinksheep-ia — l'assistant PinkSheep.

  pinksheep-ia                    ouvre la fenêtre (SUPER + A)
  pinksheep-ia "ouvre mon CV"     même chose dans le terminal
  pinksheep-ia --etat             moteur, modèle, téléchargement
  pinksheep-ia --materiel         ce que PinkSheep a choisi pour ce PC
  pinksheep-ia --mode local|en_ligne|mixte
  pinksheep-ia --cle claude|openai        ranger une clé d'API dans le trousseau
  pinksheep-ia --oublier-cle claude|openai
"""
from __future__ import annotations

import getpass
import json
import os
import sys
from dataclasses import asdict
from pathlib import Path

from . import actions, cerveau, fournisseurs, materiel


def etat() -> int:
    r = fournisseurs.reglages()
    print(f"Mode : {r.get('mode')}")
    print(f"Modèle local : {r.get('modele_local') or 'aucun (assistant désactivé sur ce PC ?)'}")
    print(f"Moteur Ollama : {fournisseurs.etat_ollama(r.get('modele_local'))}")
    fichier = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "pinksheep" / "ia-modele.json"
    try:
        e = json.loads(fichier.read_text())
        print(f"Téléchargement du modèle : {e.get('etat')} ({e.get('quand', '')}) {e.get('detail', '')}".rstrip())
    except (OSError, ValueError):
        print("Téléchargement du modèle : pas encore commencé")
    if r.get("mode") != "local":
        t = r.get("en_ligne", {}).get("type", "claude")
        print(f"Clé {t} dans le trousseau : {'oui' if fournisseurs.lire_cle(t) else 'non'}")
    return 0


def terminal(demande: str) -> int:
    a = cerveau.Assistant()
    try:
        prop = a.proposer(demande)
    except (actions.Refus, fournisseurs.Indisponible) as e:
        print(e)
        return 1
    if prop.message and prop.action != "repondre":
        print(prop.message)
    confirme = False
    if prop.niveau == actions.CONFIRMER:
        rep = input(f"Je propose : {prop.resume()} ? [o/N] ").strip().lower()
        if rep not in ("o", "oui", "y"):
            print("D'accord, je ne fais rien.")
            return 0
        confirme = True
    try:
        print(actions.executer(prop, confirme=confirme))
    except actions.Refus as e:
        print(e)
        return 1
    return 0


def main(argv: list[str]) -> int:
    if not argv:
        from .fenetre import lancer
        return lancer()
    if argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0
    if argv[0] == "--etat":
        return etat()
    if argv[0] == "--materiel":
        print(json.dumps(asdict(materiel.detecter()), ensure_ascii=False, indent=2))
        return 0
    if argv[0] == "--mode" and len(argv) == 2 and argv[1] in ("local", "en_ligne", "mixte"):
        r = fournisseurs.reglages()
        r["mode"] = argv[1]
        fournisseurs.enregistrer_reglages(r)
        print(f"Mode : {argv[1]}")
        return 0
    if argv[0] == "--cle" and len(argv) == 2 and argv[1] in ("claude", "openai"):
        cle = getpass.getpass(f"Clé d'API {argv[1]} (rien ne s'affiche, elle va dans le trousseau) : ").strip()
        if not cle:
            return 1
        fournisseurs.ranger_cle(argv[1], cle)
        print("Clé rangée dans le trousseau. Pour l'utiliser : pinksheep-ia --mode mixte (ou en_ligne).")
        return 0
    if argv[0] == "--oublier-cle" and len(argv) == 2:
        fournisseurs.oublier_cle(argv[1])
        print("Clé retirée du trousseau.")
        return 0
    if argv[0].startswith("-"):
        print(__doc__.strip())
        return 1
    return terminal(" ".join(argv))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
