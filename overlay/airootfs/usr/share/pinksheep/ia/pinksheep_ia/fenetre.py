"""Fenêtre de l'assistant (Qt 6 / QML via PySide6)."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

from PySide6.QtCore import QObject, QRunnable, QThreadPool, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from . import actions, cerveau, fournisseurs

ICI = Path(__file__).resolve().parent

COULEURS_DEFAUT = {
    "fond": "#1e1223", "surface": "#2a1830", "texte": "#f3e4ee", "discret": "#b9a3b4",
    "primaire": "#ff7eb6", "sur_primaire": "#3b0a24", "secondaire": "#c8a2ff", "erreur": "#ff6b81",
}


def couleurs() -> dict:
    f = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "pinksheep" / "ia-couleurs.json"
    c = dict(COULEURS_DEFAUT)
    try:
        c.update({k: v for k, v in json.loads(f.read_text()).items() if k in c})
    except (OSError, ValueError):
        pass
    return c


class _Tache(QRunnable):
    def __init__(self, fonction, retour):
        super().__init__()
        self.fonction, self.retour = fonction, retour

    def run(self):
        try:
            self.retour(True, self.fonction())
        except Exception as e:     # noqa: BLE001 — tout doit revenir à l'écran, jamais planter
            self.retour(False, e)


class Pont(QObject):
    """Ce que voit le QML."""
    message = Signal(str, str)                 # (qui, texte) : qui = moi | ia | erreur
    proposition = Signal(str, str)             # (id, résumé) : carte « Faire / Annuler »
    occupe = Signal(bool)
    _retour = Signal(bool, object, str)        # passage du fil de travail vers l'interface

    def __init__(self, assistant: cerveau.Assistant):
        super().__init__()
        self.assistant = assistant
        self.en_attente: dict[str, actions.Proposition] = {}
        self.pool = QThreadPool.globalInstance()
        self._retour.connect(self._apres)

    def _lancer(self, fonction, etape: str):
        self.occupe.emit(True)
        self.pool.start(_Tache(fonction, lambda ok, r: self._retour.emit(ok, r, etape)))

    @Slot(str)
    def envoyer(self, texte: str):
        texte = texte.strip()
        if not texte:
            return
        self.message.emit("moi", texte)
        self._lancer(lambda: self.assistant.proposer(texte), "proposer")

    @Slot(str)
    def faire(self, ident: str):
        prop = self.en_attente.pop(ident, None)
        if prop:
            self._lancer(lambda: actions.executer(prop, confirme=True), "executer")

    @Slot(str)
    def annuler(self, ident: str):
        if self.en_attente.pop(ident, None):
            self.message.emit("ia", "D'accord, je ne fais rien.")

    def _apres(self, ok: bool, resultat, etape: str):
        self.occupe.emit(False)
        if not ok:
            texte = str(resultat) if isinstance(resultat, (actions.Refus, fournisseurs.Indisponible)) \
                else f"Oups : {resultat}"
            self.message.emit("erreur", texte)
            return
        if etape == "executer":
            self.message.emit("ia", resultat)
            self.assistant.noter_resultat(resultat)
            return
        prop: actions.Proposition = resultat
        if prop.niveau == actions.CONFIRMER:
            self.en_attente[prop.id] = prop
            if prop.message:
                self.message.emit("ia", prop.message)
            self.proposition.emit(prop.id, prop.resume())
        else:
            if prop.message and prop.action != "repondre":
                self.message.emit("ia", prop.message)
            self._lancer(lambda: actions.executer(prop), "executer")


def lancer() -> int:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Assistant PinkSheep")
    app.setDesktopFileName("pinksheep-ia")          # → classe de fenêtre « pinksheep-ia » pour Hyprland
    app.setWindowIcon(QIcon(str(ICI / "mouton.png")))
    reglages = fournisseurs.reglages()
    pont = Pont(cerveau.Assistant(reglages))
    moteur = QQmlApplicationEngine()
    ctx = moteur.rootContext()
    ctx.setContextProperty("pont", pont)
    ctx.setContextProperty("couleurs", couleurs())
    ctx.setContextProperty("iconeMouton", QUrl.fromLocalFile(str(ICI / "mouton.png")))
    etat = fournisseurs.etat_ollama(reglages.get("modele_local")) if reglages.get("mode") != "en_ligne" else "pret"
    accueil = {
        "pret": "Salut ! Demande-moi d'ouvrir un fichier, de lancer une appli, de régler le son…",
        "absent": "Le modèle est encore en train de se télécharger (pinksheep-ia --etat). Réessaie dans un moment.",
        "eteint": "Le moteur d'IA (Ollama) ne tourne pas. Il démarre avec le PC une fois l'assistant installé.",
    }[etat]
    ctx.setContextProperty("accueil", accueil)
    moteur.load(QUrl.fromLocalFile(str(ICI / "Fenetre.qml")))
    if not moteur.rootObjects():
        return 1
    return app.exec()
