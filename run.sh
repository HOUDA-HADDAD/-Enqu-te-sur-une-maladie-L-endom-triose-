
#!/usr/bin/env bash
# run.sh : point d'entree unique du pipeline (projet endometriose GSE141549)

set -euo pipefail

# --- Chemins -------------------------------------------------------
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# --- Valeurs par defaut --------------------------------------------
INPUT_FILE="data/processed/expression_clean.tsv"
META_FILE="data/processed/metadata.tsv"
RESULTS_DIR="results"
LFC_THRESHOLD="1"
P_THRESHOLD="0.05"
TMP_DIR="$PROJECT_DIR/.pipeline_tmp"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE=""
SCRIPTS_DIR="${PIPELINE_SCRIPTS_DIR:-$PROJECT_DIR/scripts}"

# --- Fonctions -----------------------------------------------------
usage() {
    cat <<EOF
Usage : $(basename "$0") [-h] [-i fichier_tsv] [-o dossier_resultats] [-l seuil_log2FC] [-p seuil_p]

Pipeline d'analyse de l'expression genique : lesions d'endometriose
contre tissu endometrial non atteint (GEO : GSE141549).

Options :
  -h    affiche cette aide et quitte
  -i    matrice d'expression nettoyee (defaut : data/processed/expression_clean.tsv)
  -o    dossier des resultats         (defaut : results)
  -l    seuil |log2FC|                (defaut : 1)
  -p    seuil p-value ajustee         (defaut : 0.05)

Codes de retour : 0 succes, 1 erreur d'execution, 2 mauvais usage.
EOF
}

die() {
    echo "ERREUR : $1" >&2
    exit "${2:-1}"
}

is_number() {
    [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

log() {
    local msg="[$(date '+%F %T')] $1"
    echo "$msg"
    if [ -n "$LOG_FILE" ]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

cleanup() {
    local code=$?
    if [ -d "$TMP_DIR" ]; then
        rm -rf -- "$TMP_DIR"
    fi
    if [ "$code" -ne 0 ]; then
        log "Pipeline interrompu (code $code)" >&2
    fi
    exit "$code"
}

on_error() {
    echo "ERREUR : une commande a echoue a la ligne $1 de run.sh" >&2
}

check_env() {
    local cmd
    for cmd in curl python python3 sha256sum awk sed tar; do
        command -v "$cmd" >/dev/null 2>&1 || die "commande manquante : $cmd" 1
    done
    python3 -c "import openpyxl, pandas, scipy, statsmodels, matplotlib, seaborn, pytest" 2>/dev/null \
        || die "module Python manquant (openpyxl, pandas, scipy, statsmodels, matplotlib, seaborn, pytest)" 1
}

check_scripts() {
    local s
    for s in 01_download.sh convert_data.sh process_data.sh checksums.sh \
             03_metadata.sh analyse.py visualisations.py 04_archive.sh; do
        [ -f "$SCRIPTS_DIR/$s" ] || die "script introuvable : $SCRIPTS_DIR/$s" 1
    done
}

run_step() {
    local name="$1"
    shift
    local code=0

    log "Etape : $name"
    set +e
    "$@" 2>&1 | tee -a "$LOG_FILE"
    code=${PIPESTATUS[0]}
    set -e
    if [ "$code" -ne 0 ]; then
        die "l'etape '$name' a echoue (code $code)" "$code"
    fi
    log "Etape terminee : $name"
}

# --- Lecture des options -------------------------------------------
while getopts ":hi:o:l:p:" opt; do
    case "$opt" in
        h) usage; exit 0 ;;
        i) INPUT_FILE="$OPTARG" ;;
        o) RESULTS_DIR="$OPTARG" ;;
        l) LFC_THRESHOLD="$OPTARG" ;;
        p) P_THRESHOLD="$OPTARG" ;;
        \?) usage >&2; die "option inconnue : -$OPTARG" 2 ;;
        :)  usage >&2; die "l'option -$OPTARG demande une valeur" 2 ;;
    esac
done
shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
    usage >&2
    die "argument inattendu : $*" 2
fi

# --- Validation ----------------------------------------------------
is_number "$LFC_THRESHOLD" || die "-l doit etre un nombre positif (recu : '$LFC_THRESHOLD')" 2
is_number "$P_THRESHOLD"   || die "-p doit etre un nombre positif (recu : '$P_THRESHOLD')" 2
awk -v p="$P_THRESHOLD" 'BEGIN { exit !(p > 0 && p < 1) }' \
    || die "-p doit etre strictement entre 0 et 1 (recu : '$P_THRESHOLD')" 2

# --- Gestion des erreurs et interruptions --------------------------
trap 'on_error $LINENO' ERR
trap cleanup EXIT
trap 'echo "Interruption (Ctrl+C)" >&2; exit 130' INT
trap 'echo "Signal TERM recu" >&2; exit 143' TERM

# --- Preparation ---------------------------------------------------
mkdir -p data/raw data/processed "$RESULTS_DIR" "$LOG_DIR"
rm -rf -- "$TMP_DIR"
mkdir -p "$TMP_DIR"
LOG_FILE="$LOG_DIR/run_$(date '+%Y%m%d_%H%M%S').log"
export MPLBACKEND=Agg

log "Demarrage du pipeline"
log "Parametres : entree=$INPUT_FILE resultats=$RESULTS_DIR log2FC=$LFC_THRESHOLD p=$P_THRESHOLD"

check_env
check_scripts

# --- Etapes --------------------------------------------------------
run_step "Telechargement"           bash "$SCRIPTS_DIR/01_download.sh"
run_step "Conversion XLSX vers TSV" bash "$SCRIPTS_DIR/convert_data.sh"
run_step "Nettoyage par tubes"      bash "$SCRIPTS_DIR/process_data.sh"
run_step "Sommes SHA-256"           bash "$SCRIPTS_DIR/checksums.sh"
run_step "Metadonnees"              bash "$SCRIPTS_DIR/03_metadata.sh"
run_step "Analyse statistique"      python3 "$SCRIPTS_DIR/analyse.py" \
    --input "$INPUT_FILE" --meta "$META_FILE" \
    --out "$RESULTS_DIR" --lfc "$LFC_THRESHOLD" --alpha "$P_THRESHOLD"
run_step "Figures"                  python3 "$SCRIPTS_DIR/visualisations.py"
run_step "Tests pytest"             python3 -m pytest -q tests
run_step "Archivage"                bash "$SCRIPTS_DIR/04_archive.sh"

log "Pipeline termine avec succes (journal : $LOG_FILE)"
