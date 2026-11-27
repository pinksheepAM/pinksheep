#!/usr/bin/env python3
"""PinkSheep — fabrique les modèles matugen du thème Kvantum « PinkSheep ».

Source : le thème KvArcDark de Kvantum (Tsu Jan, GPL-3.0),
https://github.com/tsujan/Kvantum — dossier Kvantum/themes/kvthemes/KvArcDark.
Chaque couleur du thème est remplacée par un rôle de couleur matugen
(Material You) choisi selon sa luminosité : gris -> surfaces / textes,
bleu -> couleur principale, rouge -> erreur, violet -> tertiaire.
Le résultat (2 fichiers) est rangé dans skel/.config/matugen/modeles/ ;
matugen en tire ~/.config/Kvantum/PinkSheep/ à chaque changement de fond.

Usage : generer-modele.py <dossier KvArcDark> <dossier de sortie>
Ne sert que si on veut repartir d'une nouvelle version de KvArcDark.
"""
import colorsys
import re
import sys
from pathlib import Path

def role(nom):
    return "{{colors.%s.default.hex_stripped}}" % nom

def role_gris(l):
    """Gris bleuté d'Arc -> surface Material, du plus sombre au plus clair."""
    for seuil, nom in ((0.21, "surface_container_lowest"), (0.27, "surface"),
                       (0.31, "surface_container_low"), (0.34, "surface_container"),
                       (0.38, "surface_container_high"), (0.45, "surface_container_highest"),
                       (0.55, "outline_variant"), (0.68, "outline"), (0.80, "on_surface_variant")):
        if l < seuil:
            return nom
    return "on_surface"

def role_svg(hexa):
    r, g, b = (int(hexa[i:i + 2], 16) / 255 for i in (0, 2, 4))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    if s < 0.05 and l < 0.13:
        return None                      # ombres noires : on les garde
    if s < 0.3:
        return role_gris(l)
    deg = h * 360
    if deg < 20 or deg > 340:
        return "error"
    if 260 < deg <= 340:
        return "tertiary"
    return "primary_container" if l < 0.5 else "primary"

def svg(source):
    def remplace(m):
        nom = role_svg(m.group(1).lower())
        return m.group(0) if nom is None else "#" + role(nom)
    return re.sub(r"#([0-9a-fA-F]{6})\b", remplace, source)

# Couleurs générales de la palette Qt (section [GeneralColors])
GENERALES = {
    "window.color": "surface", "base.color": "surface_container_low",
    "alt.base.color": "surface_container", "button.color": "surface_container_high",
    "light.color": "surface_container_highest", "mid.light.color": "surface_container_high",
    "dark.color": "shadow", "mid.color": "surface_container_lowest",
    "highlight.color": "primary", "inactive.highlight.color": "primary_container",
    "text.color": "on_surface", "window.text.color": "on_surface",
    "button.text.color": "on_surface", "disabled.text.color": "outline",
    "tooltip.text.color": "on_surface", "highlight.text.color": "on_primary",
    "link.color": "primary", "link.visited.color": "tertiary",
    "progress.indicator.text.color": "on_primary",
}
# Textes posés sur la couleur principale (sélection, menus, barres de progression)
SUR_PRIMAIRE = {("PanelButtonCommand", "text.toggle.color"), ("ItemView", "text.focus.color"), ("ItemView", "text.press.color"),
                ("ItemView", "text.toggle.color"), ("MenuItem", "text.focus.color"),
                ("MenuBarItem", "text.focus.color"), ("Progressbar", "text.focus.color"),
                ("Progressbar", "text.press.color"), ("Progressbar", "text.toggle.color")}

def kvconfig(source):
    sortie, section = [], ""
    for ligne in source.splitlines():
        m = re.match(r"^\[(.+)\]$", ligne)
        if m:
            section = m.group(1)
        cle, egal, valeur = ligne.partition("=")
        if egal and cle.endswith("color"):
            if section == "GeneralColors" and cle in GENERALES:
                valeur = "#" + role(GENERALES[cle])
            else:
                v = valeur.strip().lower()
                alpha = ""
                if re.fullmatch(r"#ffffff[0-9a-f]{2}", v):
                    alpha, v = v[7:], "white"
                if v == "white":
                    nom = "on_primary" if (section, cle) in SUR_PRIMAIRE else "on_surface"
                    valeur = "#" + role(nom) + alpha
                elif v == "#000000b4":           # texte de la barre de menus
                    valeur = "#" + role("on_surface") + "b4"
                elif re.fullmatch(r"#[0-9a-f]{6}", v):
                    nom = role_svg(v[1:])
                    valeur = v if nom is None else "#" + role(nom)
            ligne = cle + "=" + valeur
        if ligne.startswith("author="):
            ligne = "author=PinkSheep, d'après KvArcDark de Tsu Jan (GPL-3.0)"
        elif ligne.startswith("comment="):
            ligne = "comment=Thème PinkSheep : couleurs générées depuis le fond d'écran (matugen)"
        sortie.append(ligne)
    return "\n".join(sortie) + "\n"

if __name__ == "__main__":
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    dst.mkdir(parents=True, exist_ok=True)
    entete = "<!-- PinkSheep : modèle matugen dérivé de KvArcDark (Kvantum, Tsu Jan, GPL-3.0). Généré par outils/kvantum/generer-modele.py -->\n"
    texte_svg = (src / "KvArcDark.svg").read_text()
    if texte_svg.startswith("<?xml"):
        decl, _, reste = texte_svg.partition("?>")
        texte_svg = decl + "?>\n" + entete + reste.lstrip("\n")
    else:
        texte_svg = entete + texte_svg
    (dst / "kvantum.svg").write_text(svg(texte_svg))
    (dst / "kvantum.kvconfig").write_text(
        "# PinkSheep : modèle matugen dérivé de KvArcDark (Kvantum, Tsu Jan, GPL-3.0)\n"
        + kvconfig((src / "KvArcDark.kvconfig").read_text()))
    print("modèles écrits dans", dst)
