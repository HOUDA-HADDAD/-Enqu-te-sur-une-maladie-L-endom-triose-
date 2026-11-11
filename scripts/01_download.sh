
#!/usr/bin/env bash

set -euo pipefail

# Trouver automatiquement la racine du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Charger les fonctions communes
source scripts/lib.sh

# Dossier de destination
RAW_DIR="data/raw"
ensure_dir "$RAW_DIR"

# Vérifier les outils nécessaires
for cmd in curl sha256sum gzip chmod; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "$cmd n'est pas installé"
        exit 1
    fi
done

# --------------------------------------------------
# 1. Fichier Excel : matrice d'expression
# --------------------------------------------------

EXCEL_URL="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE141nnn/GSE141549/suppl/GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx"

EXCEL_FILE="GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx"

# --------------------------------------------------
# 2. Fichier Series Matrix : métadonnées
# --------------------------------------------------

MATRIX_URL="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE141nnn/GSE141549/matrix/GSE141549-GPL13376_series_matrix.txt.gz"

MATRIX_FILE="GSE141549-GPL13376_series_matrix.txt.gz"


# Validation Excel
validate_excel() {
    python - "$1" <<'PY'
import sys
from openpyxl import load_workbook

workbook = None

try:
    workbook = load_workbook(
        sys.argv[1],
        read_only=True,
        data_only=True
    )

    if "Illumina HumanWG-6 v2" not in workbook.sheetnames:
        raise ValueError("Feuille principale introuvable")

    print("[INFO] Classeur Excel valide")

except Exception as error:
    print(f"[ERREUR] Fichier Excel invalide : {error}",
          file=sys.stderr)
    sys.exit(1)

finally:
    if workbook is not None:
        workbook.close()
PY
}

# Validation Series Matrix
validate_matrix() {
    if ! gzip -t "$1"; then
        log_error "Fichier Series Matrix gzip invalide"
        return 1
    fi

    log_info "Fichier Series Matrix valide"
}

# Fonction générique de téléchargement
download_file() {
    local URL="$1"
    local FILENAME="$2"
    local VALIDATOR="$3"

    local OUTPUT="$RAW_DIR/$FILENAME"
    local PART="$OUTPUT.part"
    local CHECKSUM="$OUTPUT.sha256"

    # Fichier déjà présent
    if [[ -f "$OUTPUT" ]]; then

        log_info "Fichier déjà présent : $FILENAME"

        if [[ -f "$CHECKSUM" ]]; then
            (cd "$RAW_DIR" && sha256sum -c "$FILENAME.sha256")
        else
            log_info "Checksum absent : calcul SHA-256"
            (cd "$RAW_DIR" &&
                sha256sum "$FILENAME" > "$FILENAME.sha256")
        fi

        # Validation du fichier existant
        "$VALIDATOR" "$OUTPUT"

        # Protection en lecture seule
        chmod 444 "$OUTPUT"
        log_info "Fichier protégé en lecture seule : $FILENAME"

        return 0
    fi

    # Télécharger le fichier
    log_info "Téléchargement de $FILENAME"

    touch "$PART"

    if ! curl -fL --retry 3 --retry-delay 5 \
        -C - "$URL" -o "$PART"; then

        log_error "Échec du téléchargement : $FILENAME"
        log_info "Le fichier temporaire est conservé pour reprise"
        return 1
    fi

    # Vérifier que le fichier n'est pas vide
    if [[ ! -s "$PART" ]]; then
        log_error "Fichier téléchargé vide : $FILENAME"
        return 1
    fi

    # Valider avant déplacement
    "$VALIDATOR" "$PART"

    # Installer le fichier
    mv "$PART" "$OUTPUT"

    # Calculer le SHA-256
    (cd "$RAW_DIR" &&
        sha256sum "$FILENAME" > "$FILENAME.sha256")

    # Vérifier le checksum
    (cd "$RAW_DIR" && sha256sum -c "$FILENAME.sha256")

    # Vérification finale
    check_file "$OUTPUT"

    # Protection en lecture seule
    chmod 444 "$OUTPUT"
    log_info "Fichier protégé en lecture seule : $FILENAME"

    log_info "Téléchargement terminé : $FILENAME"
}

# --------------------------------------------------
# Téléchargement des deux fichiers
# --------------------------------------------------

download_file "$EXCEL_URL" "$EXCEL_FILE" validate_excel

download_file "$MATRIX_URL" "$MATRIX_FILE" validate_matrix

log_info "Tous les fichiers GEO sont disponibles et validés"
