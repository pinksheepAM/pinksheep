"""Détection du matériel → quelle version d'Ollama et quelle taille de modèle.

Décision du 16/11 : PinkSheep choisit tout seul, sans rien demander.
  - NVIDIA avec pilote (nvidia-smi)       → ollama-cuda
  - AMD Radeon dédiée                      → ollama-rocm
  - sinon                                  → ollama (processeur seul)
  - trop faible (peu de mémoire, pas d'AVX) → assistant désactivé
Taille du modèle selon la mémoire de la carte graphique (ou la RAM sans carte).

On n'installe QUE le paquet accéléré (ollama-cuda / ollama-rocm) : selon l'époque,
Arch l'a fourni soit comme remplaçant d'« ollama », soit comme complément qui
dépend d'« ollama ». Demander les deux en même temps échouerait dans le 1er cas.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from dataclasses import asdict, dataclass

# Modèles retenus : bons en français et pour répondre en JSON (famille Qwen 2.5).
MODELES = {
    "grand":  ("qwen2.5:7b", 4.7),    # Go à télécharger
    "moyen":  ("qwen2.5:3b", 1.9),
    "petit":  ("qwen2.5:1.5b", 1.0),
}


@dataclass
class Profil:
    acceleration: str           # nvidia | amd | processeur | desactive
    paquets: list
    modele: str | None
    taille_go: float
    vram_go: float
    ram_go: float
    raison: str


def _commande(argv: list[str]) -> str:
    if shutil.which(argv[0]) is None:
        return ""
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=10).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def ram_go(meminfo: str | None = None) -> float:
    if meminfo is None:
        try:
            meminfo = open("/proc/meminfo").read()
        except OSError:
            return 0.0
    m = re.search(r"MemTotal:\s+(\d+)", meminfo)
    return round(int(m.group(1)) / 1024 / 1024, 1) if m else 0.0


def a_avx(cpuinfo: str | None = None) -> bool:
    if cpuinfo is None:
        try:
            cpuinfo = open("/proc/cpuinfo").read()
        except OSError:
            return True
    return bool(re.search(r"^flags\s*:.*\bavx\b", cpuinfo, re.M))


def vram_nvidia(sortie_smi: str | None = None) -> float:
    if sortie_smi is None:
        sortie_smi = _commande(["nvidia-smi", "--query-gpu=memory.total", "--format=csv,noheader,nounits"])
    valeurs = [int(x) for x in re.findall(r"\d+", sortie_smi)]
    return round(max(valeurs) / 1024, 1) if valeurs else 0.0


def vram_amd(racine: str = "/sys/class/drm") -> float:
    meilleure = 0
    try:
        for carte in os.listdir(racine):
            f = os.path.join(racine, carte, "device", "mem_info_vram_total")
            if os.path.isfile(f):
                meilleure = max(meilleure, int(open(f).read().strip() or 0))
    except OSError:
        pass
    return round(meilleure / 1024 ** 3, 1)


def choisir(lspci: str, vram_nv: float, vram_rad: float, ram: float, avx: bool) -> Profil:
    """Logique de choix, pure (testable sans le matériel)."""
    lspci = lspci.lower()
    a_nvidia = "nvidia" in lspci
    a_amd = bool(re.search(r"(vga|3d|display).*(amd|ati|radeon)", lspci))

    if ram < 8 or not avx:
        raison = "moins de 8 Go de RAM" if ram < 8 else "processeur sans AVX"
        return Profil("desactive", [], None, 0, 0, ram, f"Assistant désactivé : {raison}.")

    if a_nvidia and vram_nv == 0:
        # Pendant l'installation, le pilote NVIDIA n'est pas toujours chargé : mémoire inconnue,
        # on suppose une carte moyenne (6 Go) → modèle moyen, sans risque de saturer la carte.
        vram_nv = 6.0
    if a_nvidia and vram_nv >= 4:
        acc, paquets, memoire = "nvidia", ["ollama-cuda"], vram_nv
    elif a_amd and vram_rad >= 4:
        acc, paquets, memoire = "amd", ["ollama-rocm"], vram_rad
    else:
        acc, paquets, memoire = "processeur", ["ollama"], 0.0

    if acc == "processeur":
        taille = "moyen" if ram >= 16 else "petit"
    else:
        # garder de la place pour le bureau et les jeux : ~1,5 Go de marge
        taille = "grand" if memoire >= 8 else "moyen"
    modele, go = MODELES[taille]
    detail = {"nvidia": f"carte NVIDIA ({vram_nv} Go)", "amd": f"carte AMD ({vram_rad} Go)",
              "processeur": "processeur seul"}[acc]
    return Profil(acc, paquets, modele, go, memoire, ram, f"{detail}, {ram} Go de RAM → {modele}")


def detecter() -> Profil:
    lspci = _commande(["lspci"])
    vnv = vram_nvidia() if "nvidia" in lspci.lower() else 0.0
    return choisir(lspci, vnv, vram_amd(), ram_go(), a_avx())


if __name__ == "__main__":
    print(json.dumps(asdict(detecter()), ensure_ascii=False, indent=2))
