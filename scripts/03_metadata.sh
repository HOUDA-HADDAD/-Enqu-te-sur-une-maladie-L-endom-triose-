
#!/usr/bin/env bash
set -euo pipefail
# source scripts/lib.sh

INPUT="data/raw/GSE141549-GPL13376_series_matrix.txt.gz"
OUTPUT="data/processed/metadata.tsv"

echo "[INFO] Début de l'extraction des métadonnées..."

if [ ! -f "$INPUT" ]; then
    echo "[ERROR] Fichier introuvable : $INPUT" >&2
    exit 1
fi

# Extrait, pour chaque échantillon : identifiant GSM, titre (= nom de colonne
# dans la matrice d'expression) et groupe (ligne "tissue: ...").
# Le titre sert de clé de jointure avec la matrice : les colonnes du xlsx
# ne sont pas dans le même ordre que les échantillons du fichier GEO.
zcat "$INPUT" | awk -F'\t' '
/^!Sample_geo_accession/ { for (i=2; i<=NF; i++) { gsub(/"/, "", $i); ids[i-1] = $i } }
/^!Sample_title/         { for (i=2; i<=NF; i++) { gsub(/"/, "", $i); titles[i-1] = $i } }
/^!Sample_characteristics_ch1/ && $2 ~ /tissue:/ {
    for (i=2; i<=NF; i++) { gsub(/"/, "", $i); groups[i-1] = $i }
}
END {
    print "SampleID\tTitle\tGroup"
    for (i=1; i<=length(ids); i++) {
        if (groups[i] != "") {
            print ids[i] "\t" titles[i] "\t" groups[i]
        }
    }
}' > "$OUTPUT"

echo "[INFO] Métadonnées extraites avec succès dans $OUTPUT"
