# Projet « Enquête sur une maladie » — Endométriose (GEO GSE141549)

## 1. Présentation du projet

Ce projet porte sur l'analyse des données d'expression génique liées à l'endométriose.

L'objectif est d'identifier les gènes dont l'expression diffère entre les lésions d'endométriose (lésions et endométriomes) et le tissu endométrial non atteint.

Les données proviennent de la base **Gene Expression Omnibus (GEO)** du NCBI.

- **Identifiant GEO :** GSE141549
- **Plateforme :** Illumina HumanWG-6 v2.0 (GPL13376)
- **Fichier source :** `GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx`
- **Format initial :** XLSX
- **Format traité :** TSV
- **Dimensions de la matrice :** 48 702 lignes × 338 colonnes

Les détails et les liens de téléchargement sont disponibles dans `SOURCES.md`.

### Critères de sélection des gènes

Un gène est considéré comme différentiellement exprimé lorsque les deux conditions suivantes sont respectées :

- \(|log2FC| \geq 1\)
- p-value ajustée par la méthode de Benjamini-Hochberg (BH) strictement inférieure à 0,05.

## 2. Organisation du projet

```text
projet_maladie_git/
│
├── run.sh
├── data/
│   ├── raw/
│   └── processed/
│
├── scripts/
│   ├── 01_download.sh
│   ├── checksums.sh
│   ├── convert_data.sh
│   ├── process_data.sh
│   ├── lib.sh
│   ├── 03_metadata.sh
│   ├── 04_archive.sh
│   ├── set_permissions.sh
│   ├── analyse.py
│   └── visualisations.py
│
├── tests/
│   └── test_analyse.py
│
├── results/
├── logs/
├── cron/
│   └── pipeline.cron
│
├── requirements.txt
├── checksums.sha256
├── SOURCES.md
├── M2_HANDOFF.md
└── README.md
```

Les données volumineuses sont générées localement pendant l'exécution du pipeline et ne sont pas destinées à être versionnées dans Git.

## 3. Environnement et dépendances

Environnement de développement : **Ubuntu sous WSL2**.

### Prérequis

- Bash
- Python 3 avec le module `venv`
- `curl`
- `sha256sum`
- `awk`
- `sed`
- `tar`
- Une connexion Internet pour télécharger les données GEO.

Les dépendances Python sont regroupées dans `requirements.txt`.


### Installation

**Dépôt GitHub :** [Projet Endométriose](https://github.com/HOUDA-HADDAD/-Enqu-te-sur-une-maladie-L-endom-triose-.git)

#### 1. Récupération du projet

```bash
git clone https://github.com/HOUDA-HADDAD/-Enqu-te-sur-une-maladie-L-endom-triose-.git
cd NOM_DU_DOSSIER
```

#### 2. Création de l'environnement virtuel et installation des dépendances

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
**Important :** l'environnement virtuel `.venv` doit être activé avant l'exécution de `run.sh`.

## 4. Exécution du pipeline

Le fichier `run.sh` constitue le point d'entrée principal du projet. Il automatise les différentes étapes, du téléchargement des données jusqu'à la création de l'archive des résultats.

### Commandes principales

```bash
./run.sh
```

Affiche l'aide :

```bash
./run.sh -h
```

Si le fichier n'est pas exécutable :

```bash
bash run.sh
```

### Options disponibles

| Option | Description | Valeur par défaut |
|---|---|---|
| `-h` | Afficher l'aide | — |
| `-i fichier` | Matrice d'expression nettoyée utilisée pour l'analyse | `data/processed/expression_clean.tsv` |
| `-o dossier` | Dossier de sortie des résultats | `results` |
| `-l seuil` | Seuil de \|log2FC\| | `1` |
| `-p seuil` | Seuil de p-value ajustée, strictement entre 0 et 1 | `0.05` |

Exemple :

```bash
./run.sh -l 1.5 -p 0.01 -o results_strict
```

### Étapes exécutées

Le pipeline exécute les neuf étapes suivantes :

| N° | Étape | Script |
|---|---|---|
| 1 | Téléchargement et validation des données GEO | `scripts/01_download.sh` |
| 2 | Conversion XLSX vers TSV | `scripts/convert_data.sh` |
| 3 | Nettoyage de la matrice | `scripts/process_data.sh` |
| 4 | Vérification des sommes SHA-256 | `scripts/checksums.sh` |
| 5 | Extraction des métadonnées | `scripts/03_metadata.sh` |
| 6 | Analyse statistique (test de Welch et correction BH) | `scripts/analyse.py` |
| 7 | Création des visualisations | `scripts/visualisations.py` |
| 8 | Exécution des tests automatisés | `tests/test_analyse.py` |
| 9 | Archivage des résultats | `scripts/04_archive.sh` |

### Codes de retour

- `0` : exécution réussie.
- `1` : erreur d'exécution.
- `2` : mauvaise utilisation des options ou des arguments.
- `130` : interruption par Ctrl+C.
- `143` : réception d'un signal TERM.

## 5. Résultats produits

Les résultats de l'exécution réalisée avec les paramètres par défaut sont les suivants :

- **Gènes testés :** 48 701
- **Gènes significatifs :** 1 049
- **Échantillons du groupe lésions :** 179
- **Échantillons du groupe contrôle :** 105
- **Seuil |log2FC| :** 1
- **Seuil p-value ajustée :** 0,05

### Fichiers de résultats

| Fichier | Description |
|---|---|
| `results/all_results.csv` | Résultats statistiques de l'ensemble des gènes testés |
| `results/deg.csv` | Gènes différentiellement exprimés selon les seuils définis |
| `results/summary.json` | Résumé des résultats, seuils et échantillons utilisés |
| `results/boxplot.png` | Distribution de l'expression des 20 premiers échantillons |
| `results/heatmap.png` | Heatmap des 50 gènes les plus variables |

Les résultats sont enregistrés dans le dossier `results/`.

## 6. Journaux et intégrité des données

### Journaux d'exécution

Chaque exécution du pipeline génère un journal horodaté dans le dossier `logs/`.

Exemple :

```text
logs/run_20261113_130322.log
```

Le script de nettoyage produit également :

```text
logs/process_data.log
```

Ces journaux permettent de suivre les étapes exécutées et de faciliter l'identification des erreurs.

### Vérification de l'intégrité

Les sommes de contrôle SHA-256 permettent de vérifier l'intégrité des fichiers téléchargés et traités.

Le fichier `checksums.sha256` contient la somme de référence du fichier brut.

## 7. Planification automatique et permissions

### Planification automatique (CRON)

Le dossier `cron/` contient le fichier `pipeline.cron`, réservé à la configuration de la planification automatique.

La configuration actuelle contient un exemple commenté. La tâche CRON n'est donc pas considérée comme activée.

### Gestion des permissions

Le script `scripts/set_permissions.sh` est disponible pour la gestion des permissions des fichiers du projet.

Il n'est pas appelé automatiquement par `run.sh`.

## 8. Répartition du travail

| Membre | Rôle | Éléments |
|---|---|---|
| M1 | Script principal, gestion Git et archivage | `run.sh`, Git, création des archives |
| M2 | Gestion et préparation des données | `01_download.sh`, `convert_data.sh`, `process_data.sh`, `checksums.sh`, `lib.sh`, `M2_HANDOFF.md` |
| M3 | Analyse statistique | `analyse.py` |
| M4 | Visualisations, tests et rapport | `visualisations.py`, `tests/`, `rapport.pdf` |
| M5 | Administration système et documentation | `03_metadata.sh`, `set_permissions.sh`, `cron/`, `README.md`, `SOURCES.md` |

*La répartition des fichiers est à confirmer avec les membres de l'équipe selon les responsabilités réellement attribuées.*

## 9. Remarques

1. Exécuter les commandes depuis la racine du dépôt.

2. Dépôt GitHub : [Projet Endométriose](https://github.com/HOUDA-HADDAD/-Enqu-te-sur-une-maladie-L-endom-triose-.git).

3. Pour récupérer le projet :
   ```bash
   git clone https://github.com/HOUDA-HADDAD/-Enqu-te-sur-une-maladie-L-endom-triose-.git
   ```

4. Activer l'environnement virtuel Python avant de lancer `run.sh`.

5. Ne pas ajouter les données volumineuses au dépôt Git.

6. Conserver `requirements.txt` pour reproduire l'environnement Python.

7. Consulter `SOURCES.md` pour les références et les liens de téléchargement.

8. Le pipeline complet est lancé à partir du script principal `run.sh`.
