#!/usr/bin/env python3
"""PinkSheep — planche de style des icônes (proposition, rien n'est activé).

Génère, pour chaque direction de style, les 8 icônes les plus visibles en SVG
« modèles matugen » (couleurs = {{colors.….default.hex}}), puis une planche PNG
d'aperçu avec la palette rose par défaut.

    python3 planche.py [dossier_sortie_png]
"""
import re, subprocess, sys
from pathlib import Path

ICI = Path(__file__).resolve().parent.parent          # …/pinksheep/icones
M = lambda nom: "{{colors.%s.default.hex}}" % nom      # couleur matugen
P, PC, OP, T, S, OS = M("primary"), M("primary_container"), M("on_primary"), M("tertiary"), M("surface_container_high"), M("on_surface")

# Palette d'aperçu (rose PinkSheep, celle des couleurs de secours)
APERCU = {"primary": "#ff7eb6", "primary_container": "#5c2342", "on_primary": "#3d0021",
          "tertiary": "#f8b3d0", "surface_container_high": "#30233a", "on_surface": "#f3e4ee"}

ICONES = [  # (fichier, nom affiché, emblème)
    ("folder", "Dossier", None), ("user-home", "Maison", "maison"),
    ("folder-pictures", "Images", "images"), ("folder-music", "Musique", "musique"),
    ("folder-download", "Téléchargements", "telechargements"), ("folder-documents", "Documents", "documents"),
    ("pinksheep-parametres", "Paramètres", "parametres"), ("system-software-update", "Mises à jour", "maj"),
]

# ── Emblèmes : traits arrondis, dessinés dans une boîte 20×20 (0..20) ──
EMBLEMES = {
    "maison": '<path d="M2 10 L10 3 L18 10 M5 8 V18 H15 V8 M8.5 18 V13 H11.5 V18"/>',
    "images": '<rect x="2" y="3" width="16" height="14" rx="3"/><circle cx="7" cy="8" r="1.6"/><path d="M3 15 L8 11 L11 13.5 L14 10.5 L17 14"/>',
    "musique": '<path d="M7 16 V4 L17 2 V14"/><circle cx="5" cy="16" r="2.4"/><circle cx="15" cy="14" r="2.4"/>',
    "telechargements": '<path d="M10 2 V13 M5 9 L10 14 L15 9 M3 18 H17"/>',
    "documents": '<rect x="3" y="1.5" width="14" height="17" rx="3"/><path d="M6.5 6.5 H13.5 M6.5 10 H13.5 M6.5 13.5 H11"/>',
    "maj": '<path d="M16 7 A7 7 0 0 0 4 6 M4 2 V6 H8 M4 13 A7 7 0 0 0 16 14 M16 18 V14 H12"/>',
}


def mouton(x, y, t, corps, tete, pattes):
    """Petit mouton (logo) : nuage de laine, tête et oreille, quatre pattes, à (x, y), taille t (≈ largeur)."""
    k = t / 20
    laine = "".join(f'<circle cx="{x + cx * k:.1f}" cy="{y + cy * k:.1f}" r="{r * k:.1f}"/>'
                    for cx, cy, r in [(5.5, 9.5, 3.8), (9.5, 7.2, 4.4), (13.5, 9, 4), (7.5, 12.2, 3.8), (12, 12.2, 3.8)])
    pattes_d = " ".join(f"M{x + px * k:.1f} {y + 14.5 * k:.1f} V{y + 18 * k:.1f}" for px in (6, 8.6, 11.4, 14))
    return (f'<g stroke="{pattes}" stroke-width="{1.7 * k:.1f}" stroke-linecap="round"><path d="{pattes_d}"/></g>'
            f'<g fill="{corps}">{laine}</g>'
            f'<ellipse cx="{x + 17 * k:.1f}" cy="{y + 10 * k:.1f}" rx="{2.6 * k:.1f}" ry="{3.3 * k:.1f}" fill="{tete}" '
            f'transform="rotate(-15 {x + 17 * k:.1f} {y + 10 * k:.1f})"/>'
            f'<ellipse cx="{x + 15.6 * k:.1f}" cy="{y + 7.4 * k:.1f}" rx="{1.6 * k:.1f}" ry="{0.9 * k:.1f}" fill="{tete}" '
            f'transform="rotate(-35 {x + 15.6 * k:.1f} {y + 7.4 * k:.1f})"/>')


def engrenage(cx, cy, r, couleur, trait):
    dents = "".join(f'<rect x="{cx - 1.6:.1f}" y="{cy - r - 2.2:.1f}" width="3.2" height="4" rx="1" transform="rotate({a} {cx} {cy})"/>' for a in range(0, 360, 60))
    return (f'<g fill="{couleur}">{dents}<circle cx="{cx}" cy="{cy}" r="{r}"/></g>'
            f'<circle cx="{cx}" cy="{cy}" r="{r * 0.42:.1f}" fill="{trait}"/>')


def embleme(nom, x, y, t, couleur, epaisseur):
    k = t / 20
    return (f'<g transform="translate({x} {y}) scale({k:.3f})" fill="none" stroke="{couleur}" '
            f'stroke-width="{epaisseur / k:.2f}" stroke-linecap="round" stroke-linejoin="round">{EMBLEMES[nom]}</g>')


# ── Direction A « Bonbon » : formes pleines et douces, emblème clair, mouton sur les applis ──
def bonbon(nom, emb):
    if emb in (None, "maison", "images", "musique", "telechargements", "documents"):
        corps = (f'<path d="M6 16 a5 5 0 0 1 5 -5 h12 l5 5 h25 a5 5 0 0 1 5 5 v29 a6 6 0 0 1 -6 6 h-40 a6 6 0 0 1 -6 -6z" fill="{PC}"/>'
                 f'<rect x="6" y="21" width="52" height="35" rx="7" fill="{P}"/>'
                 f'<rect x="6" y="21" width="52" height="5" rx="2.5" fill="{T}" opacity="0.55"/>')
        return corps + (embleme(emb, 22, 29, 20, OP, 3.2) if emb else "")
    if emb == "parametres":
        return (f'<rect x="5" y="5" width="54" height="54" rx="16" fill="{P}"/>'
                + mouton(12, 16, 34, "#ffffff", OP, OP) + engrenage(46, 46, 6.5, OP, P))
    return f'<circle cx="32" cy="32" r="27" fill="{P}"/>' + embleme(emb, 18, 18, 28, OP, 3.6)


# ── Direction B « Trait doux » : contours arrondis 3 px, une seule forme pleine : le mouton ──
def trait(nom, emb):
    if emb in (None, "maison", "images", "musique", "telechargements", "documents"):
        corps = (f'<path d="M8 18 a6 6 0 0 1 6 -6 h9 l5 5 h22 a6 6 0 0 1 6 6 v24 a6 6 0 0 1 -6 6 h-36 a6 6 0 0 1 -6 -6z" '
                 f'fill="{P}" fill-opacity="0.12" stroke="{P}" stroke-width="3" stroke-linejoin="round"/>')
        return corps + (embleme(emb, 23, 25, 18, P, 2.6) if emb else "")
    if emb == "parametres":
        return (f'<circle cx="32" cy="32" r="25" fill="none" stroke="{P}" stroke-width="3" stroke-dasharray="7 4.1"/>'
                + mouton(15, 17, 32, P, T, P))
    return f'<circle cx="32" cy="32" r="25" fill="{P}" fill-opacity="0.12" stroke="{P}" stroke-width="3"/>' + embleme(emb, 19, 19, 26, P, 3)


# ── Direction C « Galet » : carré très arrondi en dégradé, symbole blanc, mouton en filigrane ──
def galet(nom, emb):
    fond = (f'<defs><linearGradient id="d" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{T}"/>'
            f'<stop offset="1" stop-color="{P}"/></linearGradient></defs>'
            f'<rect x="5" y="5" width="54" height="54" rx="20" fill="url(#d)"/>'
            f'<rect x="5" y="5" width="54" height="27" rx="20" fill="#ffffff" opacity="0.10"/>')
    if emb == "parametres":
        return fond + mouton(13, 15, 36, "#ffffff", OP, OP) + engrenage(46, 46, 6, "#ffffff", P)
    dossier = '<path d="M2 6 a3 3 0 0 1 3 -3 h4 l2.5 2.5 h6.5 a3 3 0 0 1 3 3 v8 a3 3 0 0 1 -3 3 h-13 a3 3 0 0 1 -3 -3z"/>'
    if emb is None:
        return fond + (f'<g transform="translate(16 18) scale(1.6)" fill="none" stroke="#ffffff" stroke-width="1.9" '
                       f'stroke-linejoin="round">{dossier}</g>')
    return fond + embleme(emb, 18, 18, 28, "#ffffff", 3.4) + mouton(41, 9, 12, "#ffffff", P, "#ffffff").replace('fill="#ffffff"', 'fill="#ffffff" fill-opacity="0.35"', 1)


DIRECTIONS = [("bonbon", "A · Bonbon", bonbon), ("trait-doux", "B · Trait doux", trait), ("galet", "C · Galet", galet)]


def svg(contenu):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">{contenu}</svg>\n'


def apercu(texte):
    return re.sub(r"\{\{colors\.([a-z_]+)\.default\.hex\}\}", lambda m: APERCU[m.group(1)], texte)


def main():
    sortie = Path(sys.argv[1]) if len(sys.argv) > 1 else ICI / "apercu"
    sortie.mkdir(parents=True, exist_ok=True)
    lignes = []
    for dossier, titre, dessiner in DIRECTIONS:
        d = ICI / "directions" / dossier
        d.mkdir(parents=True, exist_ok=True)
        cases = []
        for i, (fichier, nom, emb) in enumerate(ICONES):
            modele = svg(dessiner(fichier, emb))
            (d / f"{fichier}.svg").write_text(modele)
            x = 190 + i * 112
            cases.append(f'<g transform="translate({x} 0)">{apercu(modele).replace('width="64" height="64"', 'x="8" y="10" width="80" height="80"', 1)}'
                         f'<text x="48" y="112" font-family="Inter, Noto Sans" font-size="12" fill="#b9a5b5" text-anchor="middle">{nom}</text></g>')
        y = 70 + len(lignes) * 150
        lignes.append(f'<g transform="translate(0 {y})"><text x="30" y="58" font-family="Inter, Noto Sans" font-size="20" '
                      f'font-weight="700" fill="#ff7eb6">{titre}</text>{"".join(cases)}</g>')
    l, h = 190 + 8 * 112 + 20, 70 + 3 * 150 + 20
    planche = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{l}" height="{h}"><rect width="100%" height="100%" fill="#1a1220"/>'
               f'<text x="30" y="42" font-family="Inter, Noto Sans" font-size="24" font-weight="700" fill="#f3e4ee">'
               f'Icônes PinkSheep : trois directions de style (couleurs = fond d\'écran)</text>{"".join(lignes)}</svg>')
    (sortie / "planche.svg").write_text(planche)
    subprocess.run(["rsvg-convert", "-o", str(sortie / "planche.png"), str(sortie / "planche.svg")], check=True)
    # Même planche sur fond clair, pour vérifier la lisibilité
    (sortie / "planche-clair.svg").write_text(planche.replace('fill="#1a1220"', 'fill="#f6eef3"', 1))
    subprocess.run(["rsvg-convert", "-o", str(sortie / "planche-clair.png"), str(sortie / "planche-clair.svg")], check=True)
    print(sortie / "planche.png")


if __name__ == "__main__":
    main()
