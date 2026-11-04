# Transmission du travail M2 — Projet Endométriose

## 1. Responsabilités réalisées

M2 : gestion des données, scripts Shell et bibliothèque de fonctions.

Les cinq critères techniques pris en charge sont :
- Pipeline de traitement contenant au moins trois commandes reliées par des tubes.
- Calcul et vérification des sommes de contrôle SHA-256.
- Création et réutilisation de fonctions dans lib.sh.
- Possibilité de relancer le traitement sans nettoyage manuel.
- Gestion d'un fichier d'entrée manquant : message d'erreur clair et code de retour non nul.

## 2. Fichiers créés

### Scripts
- scripts/convert_data.sh : conversion du fichier Excel en TSV.
- scripts/process_data.sh : nettoyage structurel de la matrice avec un pipeline awk | sed | awk.
- scripts/checksums.sh : création initiale et vérification des sommes SHA-256.
- scripts/lib.sh : fonctions Shell réutilisables.

### Données
- data/raw/ : fichier Excel original.
- data/processed/expression.tsv : matrice convertie.
- data/processed/expression_clean.tsv : matrice nettoyée.
- checksums.sha256 : sommes de contrôle des trois fichiers de données.
- logs/process_data.log : journal du nettoyage.

## 3. Fonctions disponibles dans lib.sh

- log_info : afficher un message d'information.
- log_error : afficher un message d'erreur.
- check_file : vérifier l'existence d'un fichier.
- ensure_dir : créer un dossier si nécessaire.
- verify_checksum : vérifier les sommes SHA-256.

## 4. Dépendances

- Bash.
- Python 3.
- Bibliothèque Python openpyxl.
- Commandes système : awk, sed, sha256sum, tee, wc.

## 5. Ordre d'exécution

Depuis la racine du projet :

1. Activer l'environnement Python si nécessaire.
2. Convertir le fichier Excel :
   ./scripts/convert_data.sh
3. Nettoyer la matrice :
   ./scripts/process_data.sh
4. Vérifier l'intégrité des fichiers :
   ./scripts/checksums.sh

Les scripts doivent être lancés depuis la racine du projet.

## 6. Résultats et contrôles

- Matrice convertie : 48 701 lignes de données et 336 échantillons.
- Matrice nettoyée : 48 701 lignes de données et 336 échantillons.
- Les trois fichiers contrôlés par SHA-256 ont été vérifiés avec succès.
- Un test de modification volontaire d'une somme a provoqué l'échec attendu du contrôle (code de retour 1).
- Après restauration du fichier de sommes, les trois contrôles ont de nouveau réussi.
- Le script de nettoyage a été exécuté plusieurs fois sans suppression manuelle du résultat précédent.

## 7. Remarque sur les sommes SHA-256

Au premier lancement, checksums.sh crée checksums.sha256 si ce fichier n'existe pas.
Aux lancements suivants, il vérifie les sommes existantes sans les remplacer automatiquement.

Si un fichier de données est volontairement modifié, les sommes devront être régénérées de manière contrôlée.

## 8. Intégration par M1

Les scripts utilisent des chemins relatifs à la racine du projet.
M1 doit conserver cette organisation ou adapter les chemins lors de l'intégration.

Les fichiers de données sont volumineux. Leur méthode de partage ou de stockage dans le dépôt Git doit être décidée par le groupe.
