#!/usr/bin/env bash
set -euo pipefail
source scripts/lib.sh

INPUT="data/raw/GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx"
OUTPUT="data/processed/expression.tsv"

if [[ ! -f "$INPUT" ]]; then
    echo "Erreur : fichier Excel introuvable : $INPUT" >&2
    exit 1
fi

ensure_dir "$(dirname "$OUTPUT")"
check_file "$INPUT"
log_info "Début de la conversion XLSX vers TSV"


TMP_OUTPUT=$(mktemp "${OUTPUT}.tmp.XXXXXX")
trap 'rm -f "$TMP_OUTPUT"' EXIT

echo "Conversion XLSX vers TSV..."

python - "$INPUT" "$TMP_OUTPUT" <<'PY'
import sys
import csv
from openpyxl import load_workbook

input_file = sys.argv[1]
output_file = sys.argv[2]

wb = load_workbook(input_file, read_only=True, data_only=True)
ws = wb["Illumina HumanWG-6 v2"]

with open(output_file, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f, delimiter="\t", lineterminator="\n")
    for row in ws.iter_rows(values_only=True):
        writer.writerow(["" if value is None else value for value in row])

wb.close()
print("Conversion terminée.")
PY

mv "$TMP_OUTPUT" "$OUTPUT"
trap - EXIT

log_info "Fichier créé : $OUTPUT"
ls -lh "$OUTPUT"
