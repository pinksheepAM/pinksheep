"""Actions de l'assistant PinkSheep : une liste FERMÉE d'actions typées.

Le modèle d'IA ne fabrique jamais de commande : il choisit une action de cette
liste et remplit ses arguments. Chaque action a un niveau :
  - « sur »       : se fait tout de suite (chercher, ouvrir, volume…)
  - « confirmer » : modifie quelque chose, attend qu'Irfane clique « Faire »

Garde-fous (non négociables) :
  - jamais de sudo / pkexec / su / doas / run0, ni aucune élévation ;
  - tous les chemins sont résolus (liens symboliques compris) et doivent rester
    dans le dossier personnel ;
  - les programmes lancés viennent d'une liste fixe, sans shell.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import uuid
from dataclasses import dataclass, field
from pathlib import Path

SUR = "sur"
CONFIRMER = "confirmer"

# Seuls programmes que l'assistant peut lancer (toujours sans shell)
PROGRAMMES_AUTORISES = {"xdg-open", "gio", "wpctl", "brightnessctl", "pinksheep-fond"}
INTERDITS = {"sudo", "pkexec", "su", "doas", "run0", "sudoedit", "polkit-agent-helper-1"}

# Fichiers que l'on n'« ouvre » pas sans demander : ils pourraient lancer un programme
EXTENSIONS_RISQUEES = {".desktop", ".sh", ".bash", ".zsh", ".py", ".pl", ".run", ".appimage",
                       ".exe", ".bat", ".cmd", ".jar", ".bin"}

DOSSIERS_IGNORES = {".cache", ".git", "node_modules", "Trash", ".steam", ".var", "__pycache__",
                    ".npm", ".cargo", ".rustup", ".mozilla", ".thunderbird"}


class Refus(Exception):
    """Action refusée par un garde-fou (message lisible par Irfane)."""


def dossier_perso() -> Path:
    return Path(os.path.realpath(os.path.expanduser("~")))


def chemin_sur(chemin: str, doit_exister: bool = True) -> Path:
    """Chemin résolu (liens compris) qui doit rester dans le dossier personnel."""
    if not isinstance(chemin, str) or not chemin.strip():
        raise Refus("Chemin vide.")
    perso = dossier_perso()
    brut = os.path.expanduser(chemin.strip())
    if not os.path.isabs(brut):
        brut = os.path.join(perso, brut)
    reel = Path(os.path.realpath(brut))
    if os.path.commonpath([str(perso), str(reel)]) != str(perso):
        raise Refus(f"« {chemin} » est en dehors de ton dossier personnel : je n'y touche pas.")
    if doit_exister and not reel.exists():
        raise Refus(f"« {chemin} » n'existe pas.")
    return reel


def executer_programme(argv: list[str]) -> subprocess.CompletedProcess:
    """Seule porte de sortie vers le système : liste blanche, jamais de shell."""
    if not argv:
        raise Refus("Commande vide.")
    nom = os.path.basename(argv[0])
    if nom in INTERDITS or any(os.path.basename(a) in INTERDITS for a in argv):
        raise Refus("Jamais d'élévation de droits (sudo et compagnie) : refusé.")
    if nom not in PROGRAMMES_AUTORISES:
        raise Refus(f"Programme non autorisé : {nom}")
    if shutil.which(argv[0]) is None:
        raise Refus(f"{nom} n'est pas installé.")
    return subprocess.run(argv, shell=False, capture_output=True, text=True, timeout=30,
                          stdin=subprocess.DEVNULL)


def lancer_detache(argv: list[str]) -> None:
    """Comme executer_programme, mais sans attendre (ouvrir une appli, un fichier)."""
    nom = os.path.basename(argv[0]) if argv else ""
    if nom in INTERDITS or any(os.path.basename(a) in INTERDITS for a in argv):
        raise Refus("Jamais d'élévation de droits (sudo et compagnie) : refusé.")
    if nom not in PROGRAMMES_AUTORISES:
        raise Refus(f"Programme non autorisé : {nom}")
    if shutil.which(argv[0]) is None:
        raise Refus(f"{nom} n'est pas installé.")
    subprocess.Popen(argv, shell=False, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)


# ── Les actions ────────────────────────────────────────────────

def _chercher_fichiers(nom: str, limite: int = 20) -> str:
    motif = (nom or "").strip().lower()
    if len(motif) < 2:
        raise Refus("Donne-moi au moins deux lettres du nom à chercher.")
    perso = dossier_perso()
    trouves: list[str] = []
    for racine, dossiers, fichiers in os.walk(perso, followlinks=False):
        dossiers[:] = [d for d in dossiers if d not in DOSSIERS_IGNORES]
        profondeur = len(Path(racine).relative_to(perso).parts)
        if profondeur >= 6:
            dossiers[:] = []
        for f in fichiers + dossiers:
            if motif in f.lower():
                trouves.append(str(Path(racine, f)).replace(str(perso), "~", 1))
                if len(trouves) >= limite:
                    break
        if len(trouves) >= limite:
            break
    if not trouves:
        return f"Aucun fichier ne contient « {nom} » dans son nom."
    return "J'ai trouvé :\n" + "\n".join(f"• {t}" for t in trouves)


def _ouvrir(chemin: str) -> str:
    reel = chemin_sur(chemin)
    if reel.is_file() and (reel.suffix.lower() in EXTENSIONS_RISQUEES or os.access(reel, os.X_OK)):
        raise Refus(f"« {reel.name} » est un programme ou un script : je ne le lance pas.")
    lancer_detache(["xdg-open", str(reel)])
    return f"J'ouvre {reel.name}."


def _applis_installees() -> dict[str, Path]:
    """Nom affiché (en minuscules) → fichier .desktop."""
    dossiers = [Path.home() / ".local/share/applications"]
    for d in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":"):
        dossiers.append(Path(d) / "applications")
    applis: dict[str, Path] = {}
    for d in dossiers:
        for f in sorted(d.glob("*.desktop")) if d.is_dir() else []:
            nom, cache = None, False
            try:
                for ligne in f.read_text(errors="ignore").splitlines():
                    if ligne.startswith("[") and ligne.strip() != "[Desktop Entry]" and nom:
                        break
                    if ligne.startswith("Name=") and nom is None:
                        nom = ligne[5:].strip()
                    if ligne.strip() in ("NoDisplay=true", "Hidden=true"):
                        cache = True
            except OSError:
                continue
            if nom and not cache:
                applis.setdefault(nom.lower(), f)
                applis.setdefault(f.stem.lower(), f)
    return applis


def _lancer_appli(nom: str) -> str:
    voulu = (nom or "").strip().lower()
    if not voulu:
        raise Refus("Quelle appli ?")
    applis = _applis_installees()
    fichier = applis.get(voulu) or next((p for n, p in applis.items() if voulu in n), None)
    if fichier is None:
        raise Refus(f"Je ne trouve pas d'appli « {nom} ».")
    lancer_detache(["gio", "launch", str(fichier)])
    return f"Je lance {fichier.stem}."


def _volume(pourcentage: int) -> str:
    p = int(pourcentage)
    if not 0 <= p <= 100:
        raise Refus("Le volume va de 0 à 100 %.")
    executer_programme(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{p}%"])
    return f"Volume à {p} %."


def _couper_son() -> str:
    executer_programme(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    return "Son coupé / remis."


def _luminosite(pourcentage: int) -> str:
    p = int(pourcentage)
    if not 1 <= p <= 100:
        raise Refus("La luminosité va de 1 à 100 %.")
    executer_programme(["brightnessctl", "set", f"{p}%"])
    return f"Luminosité à {p} %."


def _changer_fond(image: str) -> str:
    if image.startswith("/usr/share/pinksheep/wallpapers/"):
        reel = Path(os.path.realpath(image))
        if not str(reel).startswith("/usr/share/pinksheep/wallpapers/") or not reel.is_file():
            raise Refus("Fond introuvable.")
    else:
        reel = chemin_sur(image)
    if reel.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp", ".gif"}:
        raise Refus("Ce n'est pas une image.")
    executer_programme(["pinksheep-fond", str(reel)])
    return f"Nouveau fond : {reel.name} (et les couleurs qui vont avec)."


def _renommer(chemin: str, nouveau_nom: str) -> str:
    reel = chemin_sur(chemin)
    if reel == dossier_perso():
        raise Refus("Je ne renomme pas ton dossier personnel.")
    if not nouveau_nom or "/" in nouveau_nom or nouveau_nom in (".", "..") or "\0" in nouveau_nom:
        raise Refus("Nouveau nom invalide.")
    cible = chemin_sur(str(reel.parent / nouveau_nom), doit_exister=False)
    if cible.exists():
        raise Refus(f"« {nouveau_nom} » existe déjà : je n'écrase rien.")
    os.rename(reel, cible)
    return f"Renommé en {nouveau_nom}."


def _corbeille(chemin: str) -> str:
    reel = chemin_sur(chemin)
    if reel == dossier_perso():
        raise Refus("Je ne mets pas ton dossier personnel à la corbeille.")
    executer_programme(["gio", "trash", str(reel)])
    return f"{reel.name} est dans la corbeille (récupérable)."


def _repondre(texte: str) -> str:
    return str(texte)


@dataclass
class Definition:
    nom: str
    niveau: str
    description: str
    arguments: dict[str, type]
    fonction: object
    resume: object = None   # phrase de proposition pour la carte « Faire / Annuler »


ACTIONS: dict[str, Definition] = {d.nom: d for d in [
    Definition("repondre", SUR, "Répondre par un message, sans rien faire.", {"texte": str}, _repondre),
    Definition("chercher_fichiers", SUR, "Chercher des fichiers ou dossiers par leur nom dans le dossier personnel.",
               {"nom": str}, _chercher_fichiers),
    Definition("ouvrir", SUR, "Ouvrir un fichier ou un dossier du dossier personnel avec l'appli habituelle.",
               {"chemin": str}, _ouvrir),
    Definition("lancer_appli", SUR, "Lancer une application installée (par son nom).", {"nom": str}, _lancer_appli),
    Definition("volume", SUR, "Régler le volume (0 à 100).", {"pourcentage": int}, _volume),
    Definition("couper_son", SUR, "Couper ou remettre le son.", {}, _couper_son),
    Definition("luminosite", SUR, "Régler la luminosité de l'écran (1 à 100).", {"pourcentage": int}, _luminosite),
    Definition("changer_fond", CONFIRMER, "Changer le fond d'écran (et donc les couleurs du bureau).",
               {"image": str}, _changer_fond, lambda a: f"Changer le fond d'écran pour « {a['image']} »"),
    Definition("renommer", CONFIRMER, "Renommer un fichier ou dossier du dossier personnel.",
               {"chemin": str, "nouveau_nom": str}, _renommer,
               lambda a: f"Renommer « {a['chemin']} » en « {a['nouveau_nom']} »"),
    Definition("corbeille", CONFIRMER, "Mettre un fichier ou dossier à la corbeille (récupérable).",
               {"chemin": str}, _corbeille, lambda a: f"Mettre « {a['chemin']} » à la corbeille"),
]}


@dataclass
class Proposition:
    action: str
    arguments: dict
    message: str = ""
    id: str = field(default_factory=lambda: uuid.uuid4().hex[:8])

    @property
    def definition(self) -> Definition:
        return ACTIONS[self.action]

    @property
    def niveau(self) -> str:
        return self.definition.niveau

    def resume(self) -> str:
        d = self.definition
        return d.resume(self.arguments) if d.resume else self.message or d.description


def valider(brut: dict) -> Proposition:
    """Transforme la réponse (JSON) du modèle en proposition sûre, ou lève Refus."""
    if not isinstance(brut, dict):
        raise Refus("Réponse du modèle illisible.")
    nom = brut.get("action")
    if nom not in ACTIONS:
        raise Refus(f"Action inconnue : {nom!r}")
    definition = ACTIONS[nom]
    args = brut.get("arguments") or {}
    if not isinstance(args, dict):
        raise Refus("Arguments illisibles.")
    propres = {}
    for cle, typ in definition.arguments.items():
        if cle not in args:
            raise Refus(f"Il manque « {cle} » pour {nom}.")
        valeur = args[cle]
        try:
            propres[cle] = int(valeur) if typ is int else str(valeur)
        except (TypeError, ValueError):
            raise Refus(f"« {cle} » doit être un nombre.") from None
    message = brut.get("message") or ""
    return Proposition(nom, propres, str(message)[:500])


def executer(prop: Proposition, confirme: bool = False) -> str:
    """Exécute une proposition validée. Les actions « confirmer » exigent confirme=True."""
    if prop.action not in ACTIONS:
        raise Refus("Action inconnue.")
    if prop.niveau == CONFIRMER and not confirme:
        raise Refus("Cette action modifie quelque chose : elle attend ta confirmation.")
    return prop.definition.fonction(**prop.arguments)


def catalogue_pour_modele() -> str:
    """Description des actions, à donner au modèle."""
    lignes = []
    for d in ACTIONS.values():
        args = ", ".join(f'"{k}": {"nombre" if t is int else "texte"}' for k, t in d.arguments.items())
        lignes.append(f'- {d.nom} {{{args}}} : {d.description}')
    return "\n".join(lignes)
