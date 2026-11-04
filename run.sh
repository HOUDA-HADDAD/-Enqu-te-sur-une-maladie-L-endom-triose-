#!/usr/bin/env bash
# run.sh : point d'entree unique du pipeline (projet endometriose GSE141549)

set -euo pipefail

# --- Chemins -------------------------------------------------------
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Valeurs par defaut --------------------------------------------
DATA_DIR="$PROJECT_DIR/data"
RESULTS_DIR="$PROJECT_DIR/results"
LFC_THRESHOLD="1"
P_THRESHOLD="0.05"
TMP_DIR="$PROJECT_DIR/.pipeline_tmp"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE=""
# --- Fonctions -----------------------------------------------------
usage() {
    cat <<EOF
Usage : $(basename "$0") [-h] [-i dossier_donnees] [-o dossier_resultats] [-l seuil_log2FC] [-p seuil_p]

Pipeline d'analyse de l'expression genique : lesions d'endometriose
contre tissu endometrial non atteint (GEO : GSE141549).

Options :
  -h    affiche cette aide et quitte
  -i    dossier des donnees      (defaut : data)
  -o    dossier des resultats    (defaut : results)
  -l    seuil |log2FC|           (defaut : 1)
  -p    seuil p-value ajustee    (defaut : 0.05)

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
# --- Lecture des options -------------------------------------------
while getopts ":hi:o:l:p:" opt; do
    case "$opt" in
        h) usage; exit 0 ;;
        i) DATA_DIR="$OPTARG" ;;
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
# --- Resume provisoire ---------------------------------------------
echo "Parametres :"
echo "  donnees   : $DATA_DIR"
echo "  resultats : $RESULTS_DIR"
echo "  seuil log2FC : $LFC_THRESHOLD"
echo "  seuil p      : $P_THRESHOLD"
# --- Preparation ---------------------------------------------------
mkdir -p "$DATA_DIR/raw" "$DATA_DIR/processed" "$RESULTS_DIR" "$LOG_DIR"
rm -rf -- "$TMP_DIR"
mkdir -p "$TMP_DIR"
LOG_FILE="$LOG_DIR/run_$(date '+%Y%m%d_%H%M%S').log"

log "Demarrage du pipeline"
log "Parametres : donnees=$DATA_DIR resultats=$RESULTS_DIR log2FC=$LFC_THRESHOLD p=$P_THRESHOLD"
log "Dossier temporaire : $TMP_DIR"
log "Fin du morceau 2 (aucun script appele pour l'instant)"
