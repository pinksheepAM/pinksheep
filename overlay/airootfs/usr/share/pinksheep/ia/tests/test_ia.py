"""Tests de pinksheep-ia : garde-fous, détection du matériel, bout à bout avec un faux Ollama.

    python3 -m unittest discover -s /usr/share/pinksheep/ia/tests -v

Rien ne touche au vrai dossier personnel : HOME pointe vers un dossier temporaire.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from unittest import mock

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI.parent))

from pinksheep_ia import actions, cerveau, fournisseurs, materiel  # noqa: E402

VRAI_RUN = subprocess.run


class DossierPerso(unittest.TestCase):
    """Chaque test a son propre faux dossier personnel."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.racine = Path(self._tmp.name)
        self.perso = self.racine / "irfane"
        self.perso.mkdir()
        (self.perso / "Documents").mkdir()
        (self.perso / "Documents" / "CV Irfane.pdf").write_text("cv")
        self.dehors = self.racine / "secret.txt"
        self.dehors.write_text("à ne pas toucher")
        self._env = mock.patch.dict(os.environ, {"HOME": str(self.perso),
                                                 "XDG_CONFIG_HOME": str(self.perso / ".config"),
                                                 "XDG_STATE_HOME": str(self.perso / ".local/state")})
        self._env.start()
        self.lances: list[list[str]] = []
        self._popen = mock.patch.object(actions.subprocess, "Popen",
                                        side_effect=lambda argv, **k: self.lances.append(argv))
        self._run = mock.patch.object(actions.subprocess, "run",
                                      side_effect=lambda argv, **k: self.lances.append(argv)
                                      or subprocess.CompletedProcess(argv, 0, "", ""))
        self._which = mock.patch.object(actions.shutil, "which", side_effect=lambda n: "/usr/bin/" + n)
        self._popen.start(); self._run.start(); self._which.start()

    def tearDown(self):
        self._which.stop(); self._run.stop(); self._popen.stop(); self._env.stop()
        self._tmp.cleanup()


class GardeFous(DossierPerso):
    def test_evasion_par_points(self):
        with self.assertRaises(actions.Refus):
            actions.chemin_sur("~/../secret.txt")
        with self.assertRaises(actions.Refus):
            actions.chemin_sur("/etc/passwd")

    def test_evasion_par_lien_symbolique(self):
        (self.perso / "raccourci").symlink_to(self.dehors)
        (self.perso / "dossier-lien").symlink_to(self.racine)
        for chemin in ("~/raccourci", "~/dossier-lien/secret.txt"):
            with self.assertRaises(actions.Refus, msg=chemin):
                actions.chemin_sur(chemin)
        prop = actions.valider({"action": "corbeille", "arguments": {"chemin": "~/raccourci"}})
        with self.assertRaises(actions.Refus):
            actions.executer(prop, confirme=True)
        self.assertTrue(self.dehors.exists())

    def test_prefixe_trompeur(self):
        # /home/irfane-bis n'est pas dans /home/irfane
        voisin = self.racine / "irfane-bis"
        voisin.mkdir()
        (voisin / "x.txt").write_text("x")
        with self.assertRaises(actions.Refus):
            actions.chemin_sur(str(voisin / "x.txt"))

    def test_jamais_sudo(self):
        for argv in (["sudo", "rm", "-rf", "/"], ["pkexec", "true"], ["su", "-c", "id"],
                     ["doas", "true"], ["run0", "true"], ["wpctl", "sudo"]):
            with self.assertRaises(actions.Refus, msg=argv):
                actions.executer_programme(argv)
            with self.assertRaises(actions.Refus, msg=argv):
                actions.lancer_detache(argv)
        self.assertEqual(self.lances, [])

    def test_programme_hors_liste(self):
        for argv in (["bash", "-c", "rm -rf ~"], ["rm", "-rf", "/"], ["/bin/sh"], ["curl", "x"]):
            with self.assertRaises(actions.Refus):
                actions.executer_programme(argv)
        self.assertEqual(self.lances, [])

    def test_action_inventee_ou_shell(self):
        for brut in ({"action": "shell", "arguments": {"commande": "sudo rm -rf /"}},
                     {"action": "executer", "arguments": {}},
                     {"action": "volume", "arguments": {}},
                     {"action": "volume", "arguments": {"pourcentage": "beaucoup"}},
                     "pas un objet"):
            with self.assertRaises(actions.Refus, msg=str(brut)):
                actions.valider(brut)

    def test_destructif_demande_confirmation(self):
        cible = self.perso / "Documents" / "CV Irfane.pdf"
        prop = actions.valider({"action": "corbeille", "arguments": {"chemin": "~/Documents/CV Irfane.pdf"}})
        self.assertEqual(prop.niveau, actions.CONFIRMER)
        with self.assertRaises(actions.Refus):
            actions.executer(prop)                       # sans confirmation
        self.assertEqual(self.lances, [])
        actions.executer(prop, confirme=True)
        self.assertEqual(self.lances, [["gio", "trash", str(cible)]])

        prop = actions.valider({"action": "renommer",
                                "arguments": {"chemin": "~/Documents/CV Irfane.pdf", "nouveau_nom": "CV.pdf"}})
        with self.assertRaises(actions.Refus):
            actions.executer(prop)
        self.assertTrue(cible.exists())
        actions.executer(prop, confirme=True)
        self.assertTrue((self.perso / "Documents" / "CV.pdf").exists())

    def test_renommer_ne_sort_pas_ni_n_ecrase(self):
        (self.perso / "a.txt").write_text("a")
        (self.perso / "b.txt").write_text("b")
        for nouveau in ("../evade.txt", "x/y", "..", "b.txt"):
            prop = actions.valider({"action": "renommer", "arguments": {"chemin": "~/a.txt", "nouveau_nom": nouveau}})
            with self.assertRaises(actions.Refus, msg=nouveau):
                actions.executer(prop, confirme=True)
        self.assertEqual((self.perso / "b.txt").read_text(), "b")
        self.assertFalse((self.racine / "evade.txt").exists())

    def test_ne_lance_pas_un_script(self):
        script = self.perso / "piege.sh"
        script.write_text("#!/bin/sh\nrm -rf ~\n")
        executable = self.perso / "piege"
        executable.write_text("x"); executable.chmod(0o755)
        for chemin in ("~/piege.sh", "~/piege"):
            prop = actions.valider({"action": "ouvrir", "arguments": {"chemin": chemin}})
            with self.assertRaises(actions.Refus):
                actions.executer(prop)
        self.assertEqual(self.lances, [])

    def test_ouvrir_et_chercher(self):
        res = actions.executer(actions.valider({"action": "chercher_fichiers", "arguments": {"nom": "cv"}}))
        self.assertIn("~/Documents/CV Irfane.pdf", res)
        actions.executer(actions.valider({"action": "ouvrir", "arguments": {"chemin": "~/Documents/CV Irfane.pdf"}}))
        self.assertEqual(self.lances[-1][0], "xdg-open")

    def test_bornes_volume(self):
        for v in (-1, 101, 1000):
            with self.assertRaises(actions.Refus):
                actions.executer(actions.valider({"action": "volume", "arguments": {"pourcentage": v}}))
        actions.executer(actions.valider({"action": "volume", "arguments": {"pourcentage": 30}}))
        self.assertEqual(self.lances[-1], ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "30%"])


class CleApi(DossierPerso):
    def test_cle_jamais_ecrite_sur_disque(self):
        secret = "sk-ant-TEST-ne-doit-jamais-etre-ecrite"
        appels = []

        def faux_run(argv, **k):
            appels.append((argv, k.get("input")))
            return subprocess.CompletedProcess(argv, 0, "", "")
        with mock.patch.object(fournisseurs.shutil, "which", return_value="/usr/bin/secret-tool"), \
             mock.patch.object(fournisseurs.subprocess, "run", side_effect=faux_run):
            fournisseurs.ranger_cle("claude", secret)
        argv, entree = appels[0]
        self.assertNotIn(secret, " ".join(argv))          # pas en argument (visible dans ps)
        self.assertEqual(entree, secret)                   # passée par l'entrée standard
        # même si on essaie de l'enregistrer dans les réglages, elle n'y va pas
        fournisseurs.enregistrer_reglages({"mode": "mixte", "cle": secret, "api_key": secret,
                                           "en_ligne": {"type": "claude"}})
        for f in self.perso.rglob("*"):
            if f.is_file():
                self.assertNotIn(secret, f.read_text(errors="ignore"), str(f))


class Materiel(unittest.TestCase):
    NV = "01:00.0 VGA compatible controller: NVIDIA Corporation TU116 [GeForce GTX 1660 SUPER]"
    AMD = "03:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Navi 22 [Radeon RX 6700 XT]"
    INTEL = "00:02.0 VGA compatible controller: Intel Corporation RocketLake-S GT1 [UHD Graphics 750]"

    def test_pc_d_irfane(self):
        p = materiel.choisir(self.NV, 6.0, 0, 31.2, True)
        self.assertEqual((p.acceleration, p.paquets, p.modele), ("nvidia", ["ollama-cuda"], "qwen2.5:3b"))

    def test_nvidia_pilote_pas_encore_charge(self):
        p = materiel.choisir(self.NV, 0.0, 0, 16, True)
        self.assertEqual(p.acceleration, "nvidia")

    def test_amd_et_processeur(self):
        self.assertEqual(materiel.choisir(self.AMD, 0, 12.0, 32, True).modele, "qwen2.5:7b")
        self.assertEqual(materiel.choisir(self.AMD, 0, 12.0, 32, True).paquets, ["ollama-rocm"])
        p = materiel.choisir(self.INTEL, 0, 0, 16, True)
        self.assertEqual((p.acceleration, p.modele), ("processeur", "qwen2.5:3b"))
        self.assertEqual(materiel.choisir(self.INTEL, 0, 0, 8, True).modele, "qwen2.5:1.5b")

    def test_trop_faible(self):
        self.assertEqual(materiel.choisir(self.INTEL, 0, 0, 4, True).acceleration, "desactive")
        self.assertEqual(materiel.choisir(self.NV, 8, 0, 32, False).acceleration, "desactive")

    def test_lectures_systeme(self):
        self.assertEqual(materiel.ram_go("MemTotal:       32768000 kB\n"), 31.2)
        self.assertEqual(materiel.vram_nvidia("6144\n"), 6.0)
        self.assertTrue(materiel.a_avx("flags\t\t: fpu sse avx avx2\n"))


class FauxOllama(BaseHTTPRequestHandler):
    """Même API HTTP qu'Ollama : /api/tags et /api/chat (réponses préparées)."""
    reponses: list[str] = []
    recus: list[dict] = []

    def log_message(self, *a):
        pass

    def _json(self, donnees):
        corps = json.dumps(donnees).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(corps)))
        self.end_headers()
        self.wfile.write(corps)

    def do_GET(self):
        self._json({"models": [{"name": "qwen2.5:3b"}]})

    def do_POST(self):
        donnees = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        FauxOllama.recus.append(donnees)
        self._json({"message": {"role": "assistant", "content": FauxOllama.reponses.pop(0)}})


class BoutABout(DossierPerso):
    @classmethod
    def setUpClass(cls):
        cls.serveur = HTTPServer(("127.0.0.1", 18142), FauxOllama)
        threading.Thread(target=cls.serveur.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.serveur.shutdown()

    def setUp(self):
        super().setUp()
        self._ollama = mock.patch.object(fournisseurs, "OLLAMA", "http://127.0.0.1:18142")
        self._ollama.start()
        FauxOllama.recus.clear()
        self.ia = cerveau.Assistant({"mode": "local", "modele_local": "qwen2.5:3b", "en_ligne": {}})

    def tearDown(self):
        self._ollama.stop()
        super().tearDown()

    def test_demande_simple(self):
        FauxOllama.reponses = ['{"action": "volume", "arguments": {"pourcentage": 30}, "message": "Volume à 30 %"}']
        prop = self.ia.proposer("mets le son à 30")
        self.assertEqual(prop.action, "volume")
        self.assertEqual(actions.executer(prop), "Volume à 30 %.")
        envoye = FauxOllama.recus[0]
        self.assertEqual(envoye["format"], "json")
        self.assertIn("jamais sudo", envoye["messages"][0]["content"])

    def test_modele_qui_tente_sudo(self):
        FauxOllama.reponses = ['{"action": "commande", "arguments": {"commande": "sudo pacman -Syu"}}']
        with self.assertRaises(actions.Refus):
            self.ia.proposer("mets à jour le système")

    def test_json_entoure_de_texte(self):
        FauxOllama.reponses = ['Voilà : {"action": "chercher_fichiers", "arguments": {"nom": "CV"}, "message": "Je cherche"} !']
        prop = self.ia.proposer("trouve mon CV")
        self.assertIn("CV Irfane.pdf", actions.executer(prop))

    def test_proposition_a_confirmer(self):
        FauxOllama.reponses = ['{"action": "corbeille", "arguments": {"chemin": "~/Documents/CV Irfane.pdf"}, "message": "OK"}']
        prop = self.ia.proposer("jette mon CV")
        self.assertEqual(prop.niveau, actions.CONFIRMER)
        self.assertIn("corbeille", prop.resume())

    def test_moteur_absent(self):
        with mock.patch.object(fournisseurs, "OLLAMA", "http://127.0.0.1:18199"):
            with self.assertRaises(fournisseurs.Indisponible):
                self.ia.proposer("bonjour")
        self.assertEqual(fournisseurs.etat_ollama("qwen2.5:3b"), "pret")

    def test_cli_terminal(self):
        """La vraie commande pinksheep-ia, dans un autre processus, contre le faux Ollama."""
        FauxOllama.reponses = ['{"action": "repondre", "arguments": {"texte": "Salut Irfane !"}, "message": ""}']
        conf = Path(os.environ["XDG_CONFIG_HOME"], "pinksheep")
        conf.mkdir(parents=True, exist_ok=True)
        (conf / "ia.json").write_text('{"modele_local": "qwen2.5:3b"}')
        env = dict(os.environ, PINKSHEEP_IA_OLLAMA="http://127.0.0.1:18142",
                   PINKSHEEP_IA_DIR=str(ICI.parent))
        lanceur = ICI.parents[1] / "bin" / "pinksheep-ia"
        self._run.stop(); self._popen.stop()          # ici on veut vraiment lancer la commande
        try:
            r = VRAI_RUN(["bash", str(lanceur), "dis bonjour"], env=env, capture_output=True, text=True, timeout=60)
        finally:
            self._popen.start(); self._run.start()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("Salut Irfane !", r.stdout)

if __name__ == "__main__":
    unittest.main(verbosity=2)
