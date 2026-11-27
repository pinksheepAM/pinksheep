"""Tests du prototype Paramètres PinkSheep (sans écran, sans lancer de vrais programmes).

python3 tests/test_parametres.py
"""
import importlib.machinery, importlib.util, os, shutil, subprocess, sys, tempfile, unittest
from pathlib import Path
from unittest import mock

RACINE = Path(__file__).resolve().parent.parent / "overlay/airootfs/usr/share/pinksheep"
chargeur = importlib.machinery.SourceFileLoader("pp", str(RACINE / "bin/pinksheep-parametres"))
spec = importlib.util.spec_from_loader("pp", chargeur)
pp = importlib.util.module_from_spec(spec)
sys.dont_write_bytecode = True
chargeur.exec_module(pp)


class Actions(unittest.TestCase):
    def setUp(self):
        self.p = pp.Parametres()

    def lancer(self, action):
        with mock.patch.object(pp.shutil, "which", return_value="/bin/x"), \
             mock.patch.object(pp.subprocess, "Popen") as popen:
            self.p.lancer(action)
        return popen.call_args[0][0] if popen.called else None

    def test_chaque_action_lance_la_bonne_commande(self):
        for nom, spec in pp.ACTIONS.items():
            argv = self.lancer(nom)
            self.assertIsNotNone(argv, nom)
            if "cmd" in spec:
                self.assertEqual(argv, spec["cmd"], nom)
            else:
                self.assertEqual(argv[:3], ["pinksheep-terminal", "--class", "pinksheep-parametres"], nom)
                self.assertEqual(argv[-1], spec["terminal"], nom)

    def test_sudo_seulement_dans_un_terminal(self):
        for nom, spec in pp.ACTIONS.items():
            if "cmd" in spec:
                self.assertNotIn("sudo", " ".join(spec["cmd"]), nom)
                self.assertNotIn("pkexec", " ".join(spec["cmd"]), nom)

    def test_action_inconnue_ignoree(self):
        self.assertIsNone(self.lancer("rm -rf ~"))
        self.assertFalse(self.p.disponible("rm"))

    def test_programme_absent_bouton_desactive(self):
        with mock.patch.object(pp.shutil, "which", return_value=None), \
             mock.patch.object(pp.subprocess, "Popen") as popen:
            self.assertFalse(self.p.disponible("son"))
            self.assertEqual(self.p.manquant("son"), "pavucontrol")
            self.p.lancer("son")
            popen.assert_not_called()

    def test_couleurs_matugen(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "c.json"
            f.write_text('{"primaire": "#123456"}')
            with mock.patch.object(pp, "COULEURS", f):
                p = pp.Parametres()
            self.assertEqual(p.couleurs["primaire"], "#123456")
            self.assertEqual(p.couleurs["fond"], pp.COULEURS_DEFAUT["fond"])
            f.write_text("cassé")
            with mock.patch.object(pp, "COULEURS", f):
                self.assertEqual(pp.Parametres().couleurs["primaire"], pp.COULEURS_DEFAUT["primaire"])

    def test_etat_sans_outil(self):
        with mock.patch.object(pp.shutil, "which", return_value=None):
            self.assertEqual(self.p.etat("grub"), "inconnu")
        self.assertEqual(self.p.etat("pas-un-etat"), "inconnu")

    def test_modele_matugen_a_toutes_les_cles(self):
        import json, re
        modele = (RACINE / "skel/.config/matugen/modeles/parametres-couleurs.json").read_text()
        cles = json.loads(re.sub(r"\{\{[^}]+\}\}", "#000000", modele)).keys()
        self.assertEqual(set(cles), set(pp.COULEURS_DEFAUT))

    def test_actions_du_qml_existent(self):
        import re
        qml = (RACINE / "parametres/Parametres.qml").read_text()
        for a in re.findall(r'a: "([a-z_]+)"', qml):
            self.assertIn(a, pp.ACTIONS, a)
        for e in re.findall(r'etat: "([a-z_]+)"', qml):
            self.assertIn(e, pp.ETATS, e)


if __name__ == "__main__":
    unittest.main(verbosity=1)
