#!/usr/bin/env python3
"""
PinkSheep — traduit des modèles de couleurs wallust en modèles matugen.

Usage : wallust-vers-matugen.py DOSSIER_WALLUST DOSSIER_SORTIE

DOSSIER_WALLUST contient wallust.toml et templates/ (comme dans le dépôt
Hyprlust). On écrit dans DOSSIER_SORTIE :
  - modeles/<fichier>   les modèles réécrits pour matugen
  - config.toml         une config matugen qui les génère aux mêmes endroits

Correspondance des couleurs (palette wallust « dark » -> rôles Material) :
background, foreground, cursor, color0..color15, wallpaper.
"""
import re
import sys
import tomllib
from pathlib import Path

COULEURS = {
    "background": "surface",
    "foreground": "on_surface",
    "cursor":     "primary",
    "color0":  "surface_container",
    "color1":  "primary_container",
    "color2":  "secondary_container",
    "color3":  "tertiary_container",
    "color4":  "primary_fixed_dim",
    "color5":  "secondary_fixed_dim",
    "color6":  "tertiary_fixed_dim",
    "color7":  "on_surface_variant",
    "color8":  "outline",
    "color9":  "primary",
    "color10": "secondary",
    "color11": "tertiary",
    "color12": "primary_fixed",
    "color13": "secondary_fixed",
    "color14": "tertiary_fixed",
    "color15": "on_surface",
}

EXPR = re.compile(r"\{\{\s*([A-Za-z0-9_]+)\s*((?:\|[^}]*)?)\}\}")


def filtre(nom_filtre: str) -> str | None:
    """Traduit un filtre wallust en filtre matugen (None = format de sortie)."""
    f = nom_filtre.strip()
    m = re.fullmatch(r"(lighten|darken)\(\s*([0-9.]+)\s*\)", f)
    if m:
        amt = float(m.group(2)) * 100
        if m.group(1) == "darken":
            amt = -amt
        return f"lighten: {amt:.1f}"
    m = re.fullmatch(r'blend\(\s*"?(#[0-9A-Fa-f]{6})"?\s*\)', f)
    if m:
        return f'blend: {{{{ "{m.group(1)}" | to_color }}}}, 0.5'
    if f in ("strip", "rgb", "rgba", "xrgba", "hex"):
        return None
    return ""   # filtre inconnu : ignoré


def traduire(texte: str) -> str:
    def remplace(m: re.Match) -> str:
        var, filtres = m.group(1), m.group(2)
        if var == "wallpaper":
            return "{{image}}"
        if var == "alpha":
            return "100"
        if var not in COULEURS:
            return m.group(0)
        role = COULEURS[var]
        champ = "hex"
        transfo = []
        for brut in [x for x in filtres.split("|") if x.strip()]:
            f = brut.strip()
            if f == "strip":
                champ = "hex_stripped"
            elif f in ("rgb", "rgba", "xrgba"):
                champ = "rgba" if f != "rgb" else "rgb"
            else:
                t = filtre(f)
                if t:
                    transfo.append(t)
        if transfo:
            # les filtres matugen travaillent sur la couleur, puis on choisit le format
            base = f"colors.{role}.default.hex"
            expr = base + "".join(f" | {t}" for t in transfo)
            if champ == "hex_stripped":
                expr += ' | replace: "#", ""'
            return "{{ " + expr + " }}"
        return "{{colors." + role + ".default." + champ + "}}"
    return EXPR.sub(remplace, texte)


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    source, sortie = Path(sys.argv[1]), Path(sys.argv[2])
    conf = tomllib.load(open(source / "wallust.toml", "rb"))
    (sortie / "modeles").mkdir(parents=True, exist_ok=True)
    lignes = ["# Généré par PinkSheep à partir des modèles wallust de Hyprlust",
              "[config]", "version_check = false", ""]
    for nom, t in conf.get("templates", {}).items():
        modele = t.get("template") or t.get("src")
        cible = t.get("target") or t.get("dst")
        if not modele or not cible:
            continue
        chemin = source / "templates" / modele
        if not chemin.is_file():
            continue
        (sortie / "modeles" / modele).write_text(traduire(chemin.read_text()))
        cle = re.sub(r"[^A-Za-z0-9_]", "_", nom)
        lignes += [f"[templates.hyprlust_{cle}]",
                   f'input_path  = "./modeles/{modele}"',
                   f'output_path = "{cible}"', ""]
        print(f"  modèle traduit : {modele} -> {cible}")
    (sortie / "config.toml").write_text("\n".join(lignes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
