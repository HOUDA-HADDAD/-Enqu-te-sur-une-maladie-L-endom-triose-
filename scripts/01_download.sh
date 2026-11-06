
#!/usr/bin/env bash

set -euo pipefail

# Trouver automatiquement la racine du projet
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Charger les fonctions communes
source scripts/lib.sh

# Informations sur le fichier GEO
URL="https://ftp.ncbi.nlm.nih.gov/geo/series/GSE141nnn/GSE141549/suppl/GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx"

FILENAME="GSE141549_Illumina_HumanWG-6_v2.0_expression_beadchip_normalized.xlsx"

OUTPUT="data/raw/$FILENAME"
PART="$OUTPUT.part"
CHECKSUM="$OUTPUT.sha256"

# Vérifier que le fichier est un classeur Excel valide
validate_excel() {
    python - "$1" <<'PY'
import sys
from openpyxl import load_workbook

path = sys.argv[1]
workbook = None

try:
    with open(path, "rb") as excel_file:
        workbook = load_workbook(
            excel_file,
            read_only=True,
            data_only=True
        )

        if "Illumina HumanWG-6 v2" not in workbook.sheetnames:
            raise ValueError("Feuille principale introuvable")

        print("[INFO] Classeur Excel valide")

except Exception as error:
    print(f"[ERREUR] Fichier Excel invalide : {error}", file=sys.stderr)
    sys.exit(1)

finally:
    if workbook is not None:
        workbook.close()
PY
}

# Créer le dossier de destination
ensure_dir "data/raw"

# Vérifier la présence de curl
if ! command -v curl >/dev/null 2>&1; then
    log_error "curl n'est pas installé"
    exit 1
fi

# Si le fichier existe déjà
if [[ -f "$OUTPUT" ]]; then

    if [[ -f "$CHECKSUM" ]]; then
        log_info "Fichier déjà présent : vérification SHA-256"

        (cd data/raw && sha256sum -c "$FILENAME.sha256")

    else
        log_info "Fichier présent sans checksum : calcul SHA-256"

        (cd data/raw && sha256sum "$FILENAME" > "$FILENAME.sha256")

        (cd data/raw && sha256sum -c "$FILENAME.sha256")
    fi

    # Vérifier la structure Excel
    validate_excel "$OUTPUT"

    log_info "Fichier valide : aucun nouveau téléchargement nécessaire"
    exit 0
fi

# Télécharger ou reprendre un téléchargement interrompu
log_info "Téléchargement du fichier depuis GEO"

touch "$PART"

if ! curl -fL --retry 3 --retry-delay 5 -C - "$URL" -o "$PART"; then
    log_error "Échec du téléchargement. Le fichier temporaire est conservé pour reprise."
    exit 1
fi

# Vérifier que le téléchargement n'est pas vide
if [[ ! -s "$PART" ]]; then
    log_error "Le fichier téléchargé est vide"
    exit 1
fi

# Valider le classeur avant de le déplacer
validate_excel "$PART"

# Déplacer le fichier terminé vers sa destination
mv "$PART" "$OUTPUT"

# Calculer et enregistrer la somme SHA-256
log_info "Calcul de la somme SHA-256"

(cd data/raw && sha256sum "$FILENAME" > "$FILENAME.sha256")

# Vérifier le checksum
(cd data/raw && sha256sum -c "$FILENAME.sha256")

# Vérification finale
check_file "$OUTPUT"

log_info "Téléchargement et validation terminés avec succès"
