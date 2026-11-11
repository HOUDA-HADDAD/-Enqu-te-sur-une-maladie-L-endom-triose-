# Projet Endométriose — Analyse de données GEO GSE141549

## 1. Présentation du projet

Ce projet porte sur l'analyse de données d'expression génique liées à l'endométriose.

Les données utilisées proviennent de la base **Gene Expression Omnibus (GEO)** du NCBI.

- **Identifiant GEO :** GSE141549
- **Fichier source :** `GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx`
- **Format initial :** XLSX
- **Format traité :** TSV
- **Dimensions de la matrice :** 48 702 lignes × 338 colonnes

## 2. Organisation du projet

```text
projet_maladie_git/
│
├── data/
│   ├── raw/                 # Données originales téléchargées
│   └── processed/           # Données converties et nettoyées
│
├── scripts/
│   ├── 01_download.sh       # Téléchargement et validation des données
│   ├── checksums.sh         # Vérification SHA-256
│   ├── convert_data.sh     # Conversion XLSX vers TSV
│   ├── process_data.sh     # Nettoyage des données
│   ├── lib.sh               # Fonctions Shell réutilisables
│   ├── 03_metadata.sh       # Extraction des métadonnées
│   ├── 04_archive.sh        # Création d'archive
│   ├── analyse.py           # Analyse Python
│   └── visualisations.py   # Visualisations
│
├── results/                 # Résultats de l'analyse
├── logs/                    # Journaux d'exécution
├── cron/                    # Configuration de planification
├── tests/                   # Tests automatisés
│
├── requirements.txt         # Dépendances Python
├── checksums.sha256         # Sommes de contrôle
├── M2_HANDOFF.md            # Transmission du travail M2
└── README.md                # Documentation du projet
```

Les fichiers volumineux contenant les données ne sont pas versionnés dans Git. Ils sont générés localement pendant l'exécution des scripts.

## 3. Environnement et dépendances

Environnement de développement : Ubuntu sous WSL2.

Prérequis :
- Bash
- Python 3
- `curl`
- `sha256sum`
- `awk`
- `sed`
- `tar`

Les dépendances Python sont regroupées dans `requirements.txt`.

### Installation

Depuis la racine du projet :

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 4. Préparation et traitement des données

Les scripts M2 doivent être exécutés dans l'ordre suivant :

### Étape 1 — Téléchargement

```bash
./scripts/01_download.sh
```

Télécharge le fichier XLSX depuis GEO, vérifie sa structure et calcule son empreinte SHA-256.

### Étape 2 — Conversion

```bash
./scripts/convert_data.sh
```

Convertit le fichier Excel en fichier TSV :

`data/processed/expression.tsv`

### Étape 3 — Nettoyage

```bash
./scripts/process_data.sh
```

Nettoie la matrice et produit :

`data/processed/expression_clean.tsv`

### Étape 4 — Vérification des sommes de contrôle

```bash
./scripts/checksums.sh
```

Vérifie l'intégrité des fichiers à l'aide de SHA-256.

## 5. Journaux d'exécution

Les journaux permettent de suivre les opérations effectuées et de faciliter l'identification des erreurs.

Le script de nettoyage produit notamment :

`logs/process_data.log`

La mise en place d'un journal central horodaté pour l'exécution complète du pipeline sera intégrée avec le script principal.

## 6. Planification automatique

Le dossier `cron/` est réservé à la configuration de la planification automatique.

La configuration définitive sera documentée après l'intégration du script principal `run.sh`.

## 7. Résultats et intégrité des données

Les résultats intermédiaires sont stockés dans `data/processed/`.

Les résultats finaux de l'analyse sont destinés au dossier `results/`.

Les sommes SHA-256 permettent de vérifier que les fichiers n'ont pas été modifiés depuis le calcul de leurs empreintes de référence.

## 8. Remarques

- Exécuter les scripts depuis la racine du dépôt, sauf indication contraire.
- Ne pas ajouter les données volumineuses au dépôt Git.
- Conserver `requirements.txt` pour reproduire l'environnement Python.
- Le pipeline complet sera lancé par `run.sh` après son intégration.
