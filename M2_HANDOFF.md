# Transmission du travail M2 — Projet Endométriose

**Responsable : M2 — Gestion des données, scripts Shell et bibliothèque de fonctions**

## 1. Responsabilités prises en charge

M2 est responsable de la préparation et de la gestion des données GEO GSE141549, ainsi que des scripts Shell associés.

Les critères techniques réalisés sont :

- Création d'un pipeline de traitement contenant au moins trois commandes reliées par des tubes (`|`).
- Calcul et vérification des sommes de contrôle SHA-256.
- Création et réutilisation de fonctions dans `scripts/lib.sh`.
- Exécution répétable des traitements sans nettoyage manuel préalable.
- Gestion des fichiers d'entrée manquants avec un message d'erreur clair et un code de retour non nul.

## 2. Source des données

- **Base de données :** NCBI Gene Expression Omnibus (GEO).
- **Identifiant :** GSE141549.
- **Fichier source :** `GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx`.
- **Feuille Excel utilisée :** `Illumina HumanWG-6 v2`.
- **Format initial :** XLSX.
- **Taille approximative :** 207 Mo.

URL de téléchargement :

https://ftp.ncbi.nlm.nih.gov/geo/series/GSE141nnn/GSE141549/suppl/GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx

## 3. Fichiers réalisés

### Scripts Shell

| Fichier | Fonction |
|---|---|
| `scripts/01_download.sh` | Téléchargement et validation du fichier GEO, calcul et vérification du SHA-256. |
| `scripts/checksums.sh` | Création initiale et vérification des sommes de contrôle. |
| `scripts/convert_data.sh` | Conversion du fichier XLSX en TSV. |
| `scripts/process_data.sh` | Nettoyage structurel de la matrice avec un pipeline de trois commandes. |
| `scripts/lib.sh` | Bibliothèque de fonctions Shell réutilisables. |

### Fichiers de données générés

- `data/raw/` : fichier Excel original et son fichier SHA-256.
- `data/processed/expression.tsv` : matrice convertie.
- `data/processed/expression_clean.tsv` : matrice après nettoyage.
- `checksums.sha256` : sommes de contrôle des trois fichiers de données.
- `logs/process_data.log` : journal du traitement.

Les fichiers de données sont générés localement et ne doivent pas être ajoutés au dépôt Git en raison de leur taille.

## 4. Bibliothèque de fonctions `lib.sh`

Cinq fonctions ont été développées :

- `log_info()` : afficher un message d'information horodaté.
- `log_error()` : afficher un message d'erreur horodaté sur stderr.
- `check_file()` : vérifier l'existence d'un fichier.
- `ensure_dir()` : créer un dossier s'il n'existe pas.
- `verify_checksum()` : vérifier les sommes SHA-256 à partir d'un fichier de référence.

Ces fonctions sont réutilisées dans les scripts afin d'éviter les répétitions de code et de faciliter la maintenance.

## 5. Fonctionnement des scripts

### 5.1. Téléchargement — `01_download.sh`

Le script :

1. Identifie automatiquement la racine du projet.
2. Vérifie la disponibilité de `curl`.
3. Crée le dossier `data/raw/` si nécessaire.
4. Télécharge le fichier depuis GEO.
5. Permet de reprendre un téléchargement interrompu grâce au fichier temporaire `.part` et à l'option `curl -C -`.
6. Vérifie que le fichier téléchargé n'est pas vide.
7. Vérifie la validité du classeur Excel et la présence de la feuille attendue.
8. Déplace le fichier validé vers son emplacement définitif.
9. Calcule et vérifie son empreinte SHA-256.

Si le fichier existe déjà, le script vérifie son intégrité et sa structure avant de terminer sans effectuer un nouveau téléchargement.

### 5.2. Conversion — `convert_data.sh`

Le script utilise Python et `openpyxl` pour lire la feuille Excel en mode lecture seule et convertir les données en TSV.

Fichier produit :

`data/processed/expression.tsv`

La conversion utilise un fichier temporaire afin d'éviter de laisser un résultat incomplet en cas d'échec.

### 5.3. Nettoyage — `process_data.sh`

Le script utilise un pipeline de trois commandes reliées par des tubes :

```bash
awk 'BEGIN {FS=OFS="\t"} NR==1 {print; next} NF==338 {print}' "$INPUT" \
    | sed 's/\r$//' \
    | awk 'BEGIN {FS=OFS="\t"} NF==338 {print}' \
    > "$TMP_OUTPUT"
```

Les opérations effectuées sont :

- Conservation de l'en-tête.
- Conservation des lignes contenant 338 champs.
- Suppression éventuelle des caractères de retour chariot en fin de ligne.
- Vérification finale du nombre de champs.

Le script utilise `set -euo pipefail` et un fichier temporaire pour sécuriser le traitement.

**Résultat observé :** aucune ligne n'a été supprimée, car toutes les lignes respectaient déjà la structure attendue. Les deux fichiers TSV sont donc identiques.

### 5.4. Vérification des sommes — `checksums.sh`

Le script :

- Vérifie la présence des trois fichiers attendus.
- Crée `checksums.sha256` s'il n'existe pas.
- Vérifie les sommes existantes lors des exécutions suivantes.
- Retourne une erreur si un fichier a été modifié.

Les sommes ne sont pas remplacées automatiquement lorsqu'elles existent déjà.

## 6. Résultats obtenus et tests effectués

### 6.1. Dimensions des données

| Élément                         | Résultat |
|-----------------------------------|-------:|
| Nombre de lignes de données       | 48 701 |
| Nombre de lignes avec en-tête     | 48 702 |
| Nombre total de colonnes          | 338    |
| Nombre de colonnes d'échantillons | 33   6 |
| Nombre de colonnes d'annotation   | 2      |

Dimensions de la matrice :

**48 702 lignes × 338 colonnes**

Les dimensions ont été vérifiées après conversion et après nettoyage.

### 6.2. Contrôle des fichiers

Les sommes SHA-256 finales sont :

| Fichier                | SHA-256                                                            |
|------------------------|--------------------------------------------------------------------|
| Fichier Excel original | `8c5c34017128ab565ef36183d00be276fc78b3a0782a989fa0ab835a8cd4953f` |
| `expression.tsv`       | `b208243ce70b79f793066f7ec44f183ee94ccb45d1df4f9902494ee9325f692f` |
| `expression_clean.tsv` | `b208243ce70b79f793066f7ec44f183ee94ccb45d1df4f9902494ee9325f692f` |

Les trois fichiers ont affiché `OK` lors de la vérification avec :

```bash
sha256sum -c checksums.sha256
```

Le fichier Excel téléchargé a également été comparé à une sauvegarde locale antérieure : les deux classeurs présentaient les mêmes dimensions et les mêmes valeurs.

**Remarque :** les sommes SHA-256 assurent le contrôle d'intégrité des fichiers par rapport aux sommes enregistrées. Elles ne constituent pas une signature officielle fournie par GEO.

### 6.3. Tests techniques

Les tests suivants ont été effectués avec succès :

- Vérification syntaxique des scripts avec `bash -n`.
- Vérification des permissions d'exécution des cinq scripts.
- Vérification de la présence des fonctions dans `lib.sh`.
- Vérification du pipeline à trois commandes.
- Exécution du téléchargement et validation du classeur Excel.
- Exécution de la conversion XLSX vers TSV.
- Exécution du nettoyage sans intervention manuelle.
- Comparaison des fichiers converti et nettoyé avec `cmp`.
- Test de détection d'une modification volontaire d'un fichier dans un environnement temporaire : échec attendu avec code de retour 1.
- Vérification finale des trois sommes SHA-256 : tous les fichiers affichent `OK`.

Les permissions des fichiers TSV et de `checksums.sha256` ont également été réglées à `644`. Les scripts sont exécutables.

## 7. Dépendances et environnement

Environnement de développement :

- Ubuntu 24.04.2 LTS sous WSL2.
- Bash.
- Python 3.
- Bibliothèque Python `openpyxl`.
- Commandes système : `curl`, `awk`, `sed`, `sha256sum`, `tee`, `wc`, `cmp`.

Installation de la dépendance Python si nécessaire :

```bash
pip install openpyxl
```

## 8. Ordre d'exécution

Depuis la racine du projet :

```bash
# 1. Télécharger et vérifier les données GEO
./scripts/01_download.sh

# 2. Convertir le fichier Excel en TSV
./scripts/convert_data.sh

# 3. Nettoyer la matrice
./scripts/process_data.sh

# 4. Vérifier les sommes SHA-256
./scripts/checksums.sh
```

Les scripts `checksums.sh`, `convert_data.sh` et `process_data.sh` doivent être lancés depuis la racine du projet.

Le script `01_download.sh` identifie automatiquement cette racine.

## 9. Informations pour l'intégration par M1

- Conserver les chemins et l'organisation des dossiers, ou adapter les chemins lors de l'intégration.
- Les scripts utilisent `set -euo pipefail` pour une meilleure gestion des erreurs.
- Le fichier `checksums.sha256` doit être conservé et actualisé de manière contrôlée si les fichiers changent.
- Les données volumineuses ne doivent pas être versionnées dans Git.
- Le `.gitignore` exclut déjà les fichiers présents dans `data/raw/` et `data/processed/`, tout en conservant les fichiers `.gitkeep`.
- Le pipeline principal `run.sh` devra appeler les scripts dans l'ordre approprié.

## 10. État de transmission

La partie M2 a été développée et testée localement.

Les scripts suivants sont disponibles dans `scripts/` :

- `01_download.sh`
- `checksums.sh`
- `convert_data.sh`
- `lib.sh`
- `process_data.sh`

Le présent document décrit leur fonctionnement, leurs dépendances, les résultats obtenus et les tests réalisés.

**Les fichiers de données eux-mêmes doivent être téléchargés et vérifiés sur la machine d'exécution à l'aide des scripts fournis.**
