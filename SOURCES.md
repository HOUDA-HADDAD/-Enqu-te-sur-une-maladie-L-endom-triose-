Identifiant: GSE141549
Adresse : https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE141549
Date de telechargement : 07 novembre 2026
Taille : 206,5 Mo

- Reference de l'article : Etude associee a la serie GSE141549 sur NCBI GEO concernant l'expression genique dans l'endometriose.

## 2. Plateforme
- Description : Illumina HumanWG-6 v2.0 expression beadchip (GPL13376). Technologie de puces a l'ADN. Les donnees d'expression fournies sont deja normalisees.

## 3. Methodes statistiques
- Difference d'expression : Calcul du log2FC entre les lesions d'endometriose et le tissu endometrial non atteint.
- Test statistique : Test de Welch ou Mann-Whitney pour comparer les moyennes.
- Correction : Ajustement des p-values par la methode de Benjamini-Hochberg (BH).
- Seuils (Motif) : |log2FC| >= 1 et p-value ajustee < 0,05.

## 4. Outils et Bibliotheques
- Langages : Bash, Python 3
- Manipulation de donnees : pandas, xlsx2csv
- Statistiques : scipy (scipy.stats), statsmodels
- Visualisation : matplotlib, seaborn
- Tests automatises : pytest
 
