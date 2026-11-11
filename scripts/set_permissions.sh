#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Rendre les scripts Shell exécutables
find scripts -maxdepth 1 -type f -name "*.sh" \
    -exec chmod 755 {} +

# Protéger les données brutes contre la modification
find data/raw -maxdepth 1 -type f \
    ! -name "*.part" \
    -exec chmod 444 {} +

echo "[INFO] Permissions des scripts et des données vérifiées."
