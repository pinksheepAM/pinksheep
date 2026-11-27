# PinkSheep × Caelestia

Intégration du shell [Caelestia](https://github.com/caelestia-dots) (GPL-3.0) dans PinkSheep,
en **versions figées et testées ensemble**, avec repli automatique sur la session classique.

Le plan complet (analyse, choix, points de rupture, tests) est dans le doc
« PinkSheep × Caelestia — plan d'intégration et de packaging ».

## Contenu

| Chemin | Rôle |
|---|---|
| `versions.conf` | L'ensemble de versions figé (le « lot ») |
| `paquets/` | Une recette (PKGBUILD) par paquet du dépôt PinkSheep |
| `outils/verifier-deps.sh` | D'où vient chaque dépendance (officiel, PinkSheep, manquant) |
| `outils/construire-depot.sh` | Construit les paquets dans un chroot propre, signe, publie |
| `outils/activer-caelestia.sh` | Installe la session Caelestia sur un PC PinkSheep |
| `tests/tester-caelestia.sh` | Tests automatiques + liste de vérifications à la main |

## En 4 commandes (VM atelier, puis PC)

```bash
outils/verifier-deps.sh                      # 1. tout a une origine ?
outils/construire-depot.sh --sans-signature  # 2. premier essai, dépôt local
sudo outils/activer-caelestia.sh --depot-local _depot   # 3. sur le PC de test
tests/tester-caelestia.sh                    # 4. dans la session « PinkSheep (Caelestia) »
```

## Règles

1. On ne change jamais une seule version : on change le lot entier, on reconstruit, on teste.
2. On ne masque jamais un paquet officiel : le dépôt PinkSheep passe après les dépôts Arch.
3. On ne lance jamais `caelestia install` ni `caelestia update` (bloqués par le paquet).
4. La session « PinkSheep classique » reste toujours installée : c'est la roue de secours.

Crédits : Caelestia par soramane et ses contributeurs (GPL-3.0), m3shapes (Apache-2.0),
Quickshell par outfoxxed (LGPL-3.0, paquet officiel Arch).
