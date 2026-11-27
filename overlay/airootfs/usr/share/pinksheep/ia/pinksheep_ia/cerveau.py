"""Le lien entre la demande d'Irfane, le modèle et les actions.

Le modèle répond toujours en JSON :  {"action": ..., "arguments": {...}, "message": ...}
Cette réponse est validée (actions.valider) : une action inconnue, des arguments
manquants ou un chemin hors du dossier personnel sont refusés avant d'aller plus loin.
"""
from __future__ import annotations

import json
import re

from . import actions, fournisseurs

SYSTEME = """Tu es l'assistant de PinkSheep, une distribution Linux. Tu parles français, \
simplement et brièvement, et tu tutoies.
Tu ne peux agir QUE par une de ces actions (aucune autre, jamais de commande shell, jamais sudo) :
{catalogue}
Les chemins sont dans le dossier personnel de l'utilisateur ; écris-les avec ~ (ex. ~/Documents/CV.pdf).
Si on te demande quelque chose qui sort de cette liste, ou qui toucherait au système, \
utilise "repondre" pour expliquer gentiment que tu ne peux pas.
Pour ouvrir un fichier dont tu ne connais pas l'emplacement exact, commence par chercher_fichiers.
Réponds UNIQUEMENT par un objet JSON de la forme :
{{"action": "nom", "arguments": {{...}}, "message": "phrase courte pour l'utilisateur"}}"""


def extraire_json(texte: str) -> dict:
    texte = (texte or "").strip()
    try:
        return json.loads(texte)
    except ValueError:
        m = re.search(r"\{.*\}", texte, re.S)
        if m:
            try:
                return json.loads(m.group(0))
            except ValueError:
                pass
    raise actions.Refus("Le modèle n'a pas répondu dans le bon format.")


class Assistant:
    def __init__(self, reglages: dict | None = None):
        self.reglages = reglages or fournisseurs.reglages()
        self.historique: list[dict] = []

    def _penser(self, demande: str) -> str:
        systeme = SYSTEME.format(catalogue=actions.catalogue_pour_modele())
        messages = self.historique[-8:] + [{"role": "user", "content": demande}]
        mode = self.reglages.get("mode", "local")
        if mode == "en_ligne":
            return fournisseurs.en_ligne(systeme, messages, self.reglages.get("en_ligne", {}))
        try:
            return fournisseurs.local(systeme, messages, self.reglages.get("modele_local"))
        except fournisseurs.Indisponible:
            if mode == "mixte":
                return fournisseurs.en_ligne(systeme, messages, self.reglages.get("en_ligne", {}))
            raise

    def proposer(self, demande: str) -> actions.Proposition:
        """Demande → proposition validée (ou exception Refus / Indisponible)."""
        brut = self._penser(demande)
        try:
            prop = actions.valider(extraire_json(brut))
        except actions.Refus:
            # mode mixte : le petit modèle local s'est trompé → on demande à l'IA en ligne
            if self.reglages.get("mode") != "mixte":
                raise
            brut = fournisseurs.en_ligne(SYSTEME.format(catalogue=actions.catalogue_pour_modele()),
                                         self.historique[-8:] + [{"role": "user", "content": demande}],
                                         self.reglages.get("en_ligne", {}))
            prop = actions.valider(extraire_json(brut))
        self.historique += [{"role": "user", "content": demande}, {"role": "assistant", "content": brut}]
        return prop

    def noter_resultat(self, texte: str) -> None:
        """Le résultat d'une action (ex. liste de fichiers trouvés) sert pour la suite."""
        self.historique.append({"role": "user", "content": f"(résultat de l'action) {texte}"})
