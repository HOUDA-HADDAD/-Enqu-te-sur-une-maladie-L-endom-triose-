#!/usr/bin/env bash
set -euo pipefail

source scripts/lib.sh

CHECKSUM_FILE="checksums.sha256"

FILES=(
    "data/raw/GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx"
    "data/processed/expression.tsv"
    "data/processed/expression_clean.tsv"
)

for file in "${FILES[@]}"; do
    check_file "$file"
done

if [[ -f "$CHECKSUM_FILE" ]]; then
    log_info "Vérification des sommes SHA-256 existantes"
    verify_checksum "$CHECKSUM_FILE"
else
    log_info "Création des sommes SHA-256"

    TMP_FILE=$(mktemp)
    trap 'rm -f "$TMP_FILE"' EXIT

    sha256sum "${FILES[@]}" > "$TMP_FILE"
    mv "$TMP_FILE" "$CHECKSUM_FILE"

    trap - EXIT
    verify_checksum "$CHECKSUM_FILE"
fi

log_info "Contrôle d'intégrité terminé."
