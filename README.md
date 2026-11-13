# Projet Endométriose — Analyse de l'expression génique (GEO GSE141549)

## 1. Présentation

Comparaison de l'expression des gènes entre **lésions d'endométriose** et **tissu endométrial non atteint**, à partir du jeu de données GEO GSE141549 (puce Illumina HumanWG-6 v2.0).

Le projet est un pipeline reproductible : un seul script, `run.sh`, va de la donnée brute aux résultats.

**Motif recherché :** un gène est retenu si |log2FC| ≥ 1 et si sa p-value ajustée (Benjamini-Hochberg) est < 0,05. Les deux seuils sont des paramètres de `run.sh` (`-l` et `-p`).

**Données :**
- Fichier d'expression : `GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx` (environ 206 Mo).
- Métadonnées : `GSE141549-GPL13376_series_matrix.txt.gz`.
- Matrice nettoyée : 48 701 lignes de données (hors en-tête) × 338 colonnes (valeurs annoncées par M2, contrôlées par `tests/test_analyse.py`).
- Identifiant, adresse et date de téléchargement : voir `SOURCES.md`.

**Définition des groupes** (dans `scripts/analyse.py`) : contrôles = échantillons « endometrium » ; lésions = groupes « lesion » et « endometrioma » ; les échantillons « Peritoneum » sont exclus. L'association se fait par titre d'échantillon (nom de colonne de la matrice).

## 2. Prérequis

- Ubuntu (testé sous WSL2, Ubuntu 24.04, Python 3.12) avec accès à Internet.
- Paquets système : `sudo apt install python3-venv git curl cron`
  (`python3-venv` est indispensable : sans lui, `python3 -m venv` échoue sur Ubuntu).
- Outils standards d'Ubuntu utilisés par les scripts : `bash`, `awk`, `sed`, `tar`, `gzip`, `sha256sum`.
- Espace disque : prévoir plusieurs Go libres (fichier XLSX d'environ 206 Mo, matrices TSV, environnement Python).

## 3. Installation

```bash
git clone https://github.com/HOUDA-HADDAD/-Enqu-te-sur-une-maladie-L-endom-triose-.git projet_maladie_git
cd projet_maladie_git
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Les versions des bibliothèques sont fixées dans `requirements.txt`. **Il faut réactiver l'environnement (`source .venv/bin/activate`) dans chaque nouveau terminal** : `run.sh` ne l'active pas lui-même et s'arrête avec un message clair si `python` ou une bibliothèque manque.

## 4. Utilisation

Depuis la racine du projet, avec `.venv` activé :

```bash
./run.sh -h     # affiche l'aide
./run.sh        # pipeline complet, seuils par défaut
./run.sh -l 1.5 -p 0.01
```

| Option | Rôle | Défaut |
|---|---|---|
| `-h` | affiche l'aide et quitte | |
| `-i` | matrice d'expression nettoyée (entrée de `analyse.py`) | `data/processed/expression_clean.tsv` |
| `-o` | dossier des résultats de `analyse.py` | `results` |
| `-l` | seuil de \|log2FC\| | `1` |
| `-p` | seuil de p-value ajustée | `0.05` |

Codes de retour : `0` succès, `1` erreur d'exécution (le pipeline s'arrête à la première étape en échec), `2` mauvais usage (option inconnue ou valeur invalide).

Relance : `run.sh` peut être relancé sans nettoyage manuel. Un fichier déjà téléchargé est vérifié (SHA-256) puis réutilisé.

## 5. Étapes exécutées par `run.sh` (dans l'ordre)

| # | Étape | Script | Produit |
|---|---|---|---|
| 1 | Téléchargement et validation | `scripts/01_download.sh` | `data/raw/` : fichier XLSX, `series_matrix`, et leurs `.sha256` |
| 2 | Conversion XLSX vers TSV | `scripts/convert_data.sh` | `data/processed/expression.tsv` |
| 3 | Nettoyage par tubes | `scripts/process_data.sh` | `data/processed/expression_clean.tsv` |
| 4 | Sommes SHA-256 | `scripts/checksums.sh` | contrôle de `checksums.sha256` |
| 5 | Métadonnées | `scripts/03_metadata.sh` | `data/processed/metadata.tsv` |
| 6 | Analyse statistique | `scripts/analyse.py` | `results/all_results.csv`, `results/deg.csv`, `results/summary.json` |
| 7 | Figures | `scripts/visualisations.py` | `results/boxplot.png`, `results/heatmap.png` |
| 8 | Tests | `pytest -q tests` | résultat dans le journal |
| 9 | Archivage | `scripts/04_archive.sh` | `results_AAAAMMJJ_HHMM.tar.gz` (à la racine) |

L'analyse utilise un test de Welch puis une correction de Benjamini-Hochberg. Le log2FC est la différence des moyennes entre lésions et contrôles, ce qui suppose des valeurs déjà en échelle log2.

## 6. Journaux

- `logs/run_AAAAMMJJ_HHMMSS.log` : un fichier horodaté par exécution de `run.sh`. Il contient les étapes horodatées du pipeline ainsi que la sortie des scripts exécutés (sorties standard et erreurs).
- `logs/process_data.log` : journal du nettoyage (`process_data.sh`), avec les messages de début, de fin et le nombre de lignes conservées.
- `logs/cron.log` : sortie standard et erreurs des exécutions planifiées.

## 7. Permissions

- Scripts : exécutables (`755`). Git conserve ce bit.
- Données brutes : lecture seule (`444`). `01_download.sh` applique `chmod 444` aux fichiers GEO après téléchargement et validation.
- `scripts/set_permissions.sh` (optionnel) remet `755` sur `scripts/*.sh` et `444` sur les fichiers de `data/raw/` (sauf les `.part`).
- Vérification : `ls -l run.sh scripts data/raw`. Git ne conserve pas `444` : il est réappliqué à chaque téléchargement.

## 8. Planification (cron)

La tâche est décrite dans `cron/pipeline.cron` : chaque lundi à 02:00, elle se place à la racine du projet, active `.venv`, lance `./run.sh` et écrit dans `logs/cron.log`.

```bash
# 1. Remplacer /home/meriem/projet_maladie_git par le chemin réel dans cron/pipeline.cron
sudo service cron start      # sous WSL, le service doit être démarré
crontab -l > ~/crontab_sauvegarde.txt 2>/dev/null || true   # sauvegarde du crontab existant
crontab cron/pipeline.cron   # attention : remplace tout le crontab de l'utilisateur
crontab -l                   # vérification
```

### Désinstallation

Pour désinstaller la tâche, exécuter `crontab -e` et supprimer uniquement la ligne du pipeline.

## 9. Tests

```bash
python -m pytest -q tests
```

`tests/test_analyse.py` contrôle le fichier nettoyé, `results/deg.csv` (colonnes `log2FC` et `p_adj_BH`, seuils respectés) et la présence des figures. Il faut donc avoir exécuté le pipeline avant. `run.sh` les lance automatiquement.

## 10. Arborescence

```text
projet_maladie_git/
├── run.sh                  # point d'entrée unique
├── README.md
├── SOURCES.md              # identifiant, adresse, date, taille du jeu de données
├── requirements.txt        # dépendances Python (versions fixées)
├── checksums.sha256        # sommes de contrôle de référence
├── M2_HANDOFF.md           # transmission du travail M2
├── scripts/
│   ├── 01_download.sh      # téléchargement + SHA-256 + lecture seule
│   ├── convert_data.sh     # XLSX vers TSV
│   ├── process_data.sh     # nettoyage par tubes
│   ├── checksums.sh        # vérification SHA-256
│   ├── 03_metadata.sh      # métadonnées (groupes)
│   ├── analyse.py          # statistiques (argparse)
│   ├── visualisations.py   # figures
│   ├── 04_archive.sh       # archive tar datée
│   ├── set_permissions.sh  # droits (optionnel)
│   └── lib.sh              # fonctions Shell réutilisables
├── tests/
│   └── test_analyse.py     # tests pytest
├── cron/
│   └── pipeline.cron       # tâche planifiée
├── data/
│   ├── raw/                # données brutes (non versionnées)
│   └── processed/          # données converties (non versionnées)
├── results/                # résultats et figures (non versionnés)
└── logs/                   # journaux horodatés (non versionnés)
```

## 11. Répartition du travail

| Membre | Rôle |
|---|---|
| M1 | `run.sh`, Git, intégration, livrable final |
| M2 | téléchargement, conversion, nettoyage, sommes de contrôle, `lib.sh` |
| M3 | métadonnées, analyse statistique, archivage |
| M4 | figures, tests pytest, `SOURCES.md`, rapport |
| M5 | environnement, logs, permissions, cron, README |

## 12. Limites connues

- Option `-i` : elle ne change que l'entrée de `analyse.py` ; conversion et nettoyage utilisent des chemins fixes.
- Option `-o` : elle ne change que la sortie de `analyse.py` ; figures, tests et archivage utilisent `results/`. Pour un résultat complet, garder `-o results`.
- Les tests supposent des seuils par défaut (`log2FC` ≥ 1, p ajustée < 0,05) ou plus stricts.
- Données issues d'une puce à ADN (pas de RNA-seq), groupes déséquilibrés, tests multiples : voir le rapport.
