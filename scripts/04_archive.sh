#!/usr/bin/env bash
set -euo pipefail

DATE=$(date +%Y%m%d_%H%M)
ARCHIVE="results_${DATE}.tar.gz"

echo "[INFO] Création de l'archive $ARCHIVE..."
if [ -d "results" ]; then
    tar -czf "$ARCHIVE" results/
    echo "[INFO] Archive créée avec succès : $ARCHIVE"
else
    echo "[ERROR] Le dossier 'results/' n'existe pas encore." >&2
    exit 1
fi
