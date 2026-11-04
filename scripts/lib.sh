#!/usr/bin/env bash

# Afficher un message d'information
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Afficher un message d'erreur
log_error() {
    echo "[ERREUR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Vérifier qu'un fichier existe
check_file() {
    if [[ ! -f "$1" ]]; then
        log_error "Fichier introuvable : $1"
        return 1
    fi
    log_info "Fichier vérifié : $1"
}

# Créer un dossier s'il n'existe pas
ensure_dir() {
    mkdir -p "$1"
    log_info "Dossier disponible : $1"
}

# Calculer et vérifier une somme SHA-256
verify_checksum() {
    local checksum_file="$1"

    if [[ ! -f "$checksum_file" ]]; then
        log_error "Fichier de checksum introuvable : $checksum_file"
        return 1
    fi

    sha256sum --check "$checksum_file"
}
