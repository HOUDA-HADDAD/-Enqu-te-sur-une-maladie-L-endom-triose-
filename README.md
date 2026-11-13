# Projet « Enquête sur une maladie » — Endométriose (GEO GSE141549)

**Question :** quels gènes s'expriment différemment entre les lésions d'endométriose
(lésions + endométriomes) et l'endomètre non atteint ?

**Motif :** |log2FC| ≥ 1 **et** p-value ajustée (Benjamini-Hochberg) < 0,05.

**Données :** GEO GSE141549, puce Illumina HumanWG-6 v2.0 (GPL13376), 48 701 sondes × 336 échantillons.
Détails et adresses de téléchargement : voir `SOURCES.md`.

---

## 1. Installation

Prérequis : Linux ou WSL (Ubuntu), `bash`, `python3` (avec le module `venv`), `curl`, `gzip`,
`sha256sum`, `awk`, `sed`, `tar`. Une connexion internet est nécessaire pour télécharger les données (~207 Mo).

Depuis la racine du dépôt :

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

> Le venv doit être **activé** avant de lancer `run.sh` : le script vérifie que les modules
> Python (openpyxl, pandas, scipy, statsmodels, matplotlib, seaborn, pytest) sont disponibles.

## 2. Mode d'emploi

Un seul point d'entrée : `run.sh`. Il exécute tout le pipeline, de la donnée brute aux résultats.

```bash
./run.sh            # exécution complète avec les valeurs par défaut
./run.sh -h         # affiche l'aide
```

(Si `./run.sh` n'est pas exécutable : `bash run.sh`.)

| Option | Rôle | Défaut |
|---|---|---|
| `-h` | affiche l'aide et quitte | |
| `-i fichier` | matrice d'expression nettoyée en entrée de l'analyse | `data/processed/expression_clean.tsv` |
| `-o dossier` | dossier des résultats | `results` |
| `-l seuil` | seuil sur \|log2FC\| | `1` |
| `-p seuil` | seuil sur la p-value ajustée (entre 0 et 1) | `0.05` |

Exemple : `./run.sh -l 1.5 -p 0.01 -o results_strict`

**Codes de retour :** `0` succès, `1` erreur d'exécution (fichier manquant, étape en échec…),
`2` mauvais usage (option inconnue ou valeur invalide).
`Ctrl+C` renvoie `130`, un signal TERM renvoie `143` ; les fichiers temporaires sont supprimés.

**Durée :** quelques minutes (le téléchargement et la conversion du fichier Excel sont les étapes les plus longues).

**Relance :** `run.sh` peut être relancé sans nettoyage manuel. Le fichier brut déjà présent n'est pas
re-téléchargé (il est seulement revérifié), et un téléchargement interrompu est repris (`curl -C -`).

### Étapes exécutées par `run.sh`

| # | Étape | Script |
|---|---|---|
| 1 | Téléchargement + validation des fichiers GEO (XLSX et Series Matrix), SHA-256 | `scripts/01_download.sh` |
| 2 | Conversion XLSX → TSV | `scripts/convert_data.sh` |
| 3 | Nettoyage par tubes (`awk \| sed \| awk`) | `scripts/process_data.sh` |
| 4 | Vérification des sommes SHA-256 | `scripts/checksums.sh` |
| 5 | Extraction des métadonnées (groupes d'échantillons) | `scripts/03_metadata.sh` |
| 6 | Analyse statistique (Welch + correction BH) | `scripts/analyse.py` |
| 7 | Figures (boxplot, heatmap, volcano plot) | `scripts/visualisations.py` |
| 8 | Tests automatiques (pytest) | `tests/test_analyse.py` |
| 9 | Archivage daté des résultats (tar.gz) | `scripts/04_archive.sh` |

## 3. Organisation du dépôt

```
.
├── run.sh                  # point d'entrée unique
├── requirements.txt        # environnement Python reproductible
├── checksums.sha256        # somme SHA-256 de référence du fichier brut GEO
├── SOURCES.md              # sources des données
├── README.md
├── data/
│   ├── raw/                # données brutes téléchargées (lecture seule)
│   └── processed/          # expression.tsv, expression_clean.tsv, metadata.tsv, SHA256SUMS
├── scripts/                # scripts Shell (lib.sh = fonctions communes) et Python
├── tests/                  # tests pytest
├── results/                # résultats de l'analyse
├── logs/                   # journaux horodatés
└── cron/pipeline.cron      # tâche planifiée
```

Les données et les résultats ne sont pas versionnés dans Git : `run.sh` les génère.

## 4. Fichiers produits

| Fichier | Contenu |
|---|---|
| `data/raw/*.xlsx`, `*.txt.gz` (+ `.sha256`) | données brutes GEO, en lecture seule |
| `data/processed/expression.tsv` | matrice convertie |
| `data/processed/expression_clean.tsv` | matrice nettoyée |
| `data/processed/metadata.tsv` | identifiant GSM, titre et groupe de chaque échantillon |
| `data/processed/SHA256SUMS` | sommes des fichiers traités |
| `results/all_results.csv` | tous les gènes : moyennes, log2FC, p-value, p ajustée BH |
| `results/deg.csv` | gènes qui respectent le motif (seuils `-l` et `-p`) |
| `results/summary.json` | nombre de gènes testés/significatifs, seuils, échantillons utilisés |
| `results/boxplot.png`, `heatmap.png`, `volcano.png` | figures |
| `results_AAAAMMJJ_HHMM.tar.gz` | archive datée du dossier de résultats (racine du dépôt) |
| `logs/run_AAAAMMJJ_HHMMSS.log` | journal horodaté de chaque exécution |
| `logs/process_data.log` | journal du nettoyage |

## 5. Tests

`run.sh` lance `pytest` automatiquement (étape 8). Pour les lancer seuls, après un `run.sh` :

```bash
python3 -m pytest -q tests
```

Les tests vérifient les dimensions et l'absence de valeurs manquantes de la matrice, la présence des
colonnes de `deg.csv`, le respect des seuils (lus dans `results/summary.json`) et la production des figures.

## 6. Tâche planifiée (cron)

`cron/pipeline.cron` lance le pipeline chaque dimanche à 02h00. Le marqueur `__PROJECT_DIR__` est
remplacé par le chemin du dépôt à l'installation :

```bash
# Installer (ajoute la tâche aux tâches cron existantes de l'utilisateur)
(crontab -l 2>/dev/null; sed "s|__PROJECT_DIR__|$PWD|g" cron/pipeline.cron) | crontab -

# Vérifier
crontab -l

# Retirer la tâche : crontab -e puis supprimer les lignes du projet
```

La sortie de cron est ajoutée à `logs/cron.log`. Le venv `.venv` doit exister (voir section 1).

## 7. Journaux et permissions

- Chaque exécution écrit un journal horodaté `logs/run_AAAAMMJJ_HHMMSS.log`.
- Les scripts (`run.sh`, `scripts/*.sh`, `scripts/*.py`) sont exécutables et les données brutes sont
  en lecture seule (`chmod 444`) : `run.sh` appelle `scripts/set_permissions.sh` à chaque lancement.

## 8. Répartition du travail

| Membre | Rôle | Éléments |
|---|---|---|
| À compléter | Gestion des données, scripts Shell, bibliothèque de fonctions | `01_download.sh`, `convert_data.sh`, `process_data.sh`, `checksums.sh`, `lib.sh` |
| À compléter | Script principal et administration système | `run.sh`, `03_metadata.sh`, `04_archive.sh`, cron, permissions |
| À compléter | Analyse statistique Python | `analyse.py` |
| À compléter | Visualisations et tests | `visualisations.py`, `tests/` |
| À compléter | Rapport et documentation | `rapport.pdf`, `README.md`, `SOURCES.md` |

(Le détail du travail de gestion des données est dans `M2_HANDOFF.md`.)
