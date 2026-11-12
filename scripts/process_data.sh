#!/usr/bin/env bash
set -euo pipefail

source scripts/lib.sh

INPUT="data/processed/expression.tsv"
OUTPUT="data/processed/expression_clean.tsv"
LOG="logs/process_data.log"

ensure_dir "logs"
check_file "$INPUT"

log_info "Début du nettoyage des données" | tee -a "$LOG"

TMP_OUTPUT=$(mktemp "${OUTPUT}.tmp.XXXXXX")
trap 'rm -f "$TMP_OUTPUT"' EXIT

# Pipeline : 3 commandes reliées par des tubes
awk 'BEGIN {FS=OFS="\t"} NR==1 {print; next} NF==338 {print}' "$INPUT" \
    | sed 's/\r$//' \
    | awk 'BEGIN {FS=OFS="\t"} NF==338 {print}' \
    > "$TMP_OUTPUT"

mv "$TMP_OUTPUT" "$OUTPUT"

log_info "Nettoyage terminé" | tee -a "$LOG"

check_file "$OUTPUT"

log_info "Nombre de lignes conservées : $(wc -l < "$OUTPUT")" | tee -a "$LOG"
