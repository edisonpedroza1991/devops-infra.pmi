#!/bin/bash
# =============================================================================
# backup.sh — Script di Backup Automatico Professionale
# =============================================================================
# Autore:    Edison Pedroza Candado
# Versione:  1.0.0
# Scopo:     Backup automatico giornaliero con verifica integrità e notifiche
#
# USO:
#   chmod +x backup.sh
#   ./backup.sh
#
# CONFIGURAZIONE CRON (ogni giorno alle 02:00):
#   0 2 * * * /path/to/backup.sh >> /var/log/backup.log 2>&1
# =============================================================================

set -euo pipefail  # Termina su errore, variabile non definita o pipe fallita

# =============================================================================
# CONFIGURAZIONE — modifica questi valori per ogni cliente
# =============================================================================

readonly BACKUP_SOURCE="/var/www"           # Cartella da includere nel backup
readonly BACKUP_DEST="/backups"             # Destinazione locale dei backup
readonly REMOTE_DEST="user@remote:/backups" # Destinazione remota (SSH)
readonly RETENTION_DAYS=30                  # Giorni di backup da conservare
readonly LOG_FILE="/var/log/backup.log"     # File di log
readonly EMAIL_ALERT="cliente@azienda.it"  # Email per le notifiche
readonly BACKUP_PREFIX="backup_pmi"        # Prefisso del nome file backup

# =============================================================================
# COLORI PER OUTPUT — solo se il terminale li supporta
# =============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'  # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# =============================================================================
# FUNZIONI PRINCIPALI
# =============================================================================

# Registra un messaggio nel log e nel terminale con timestamp
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Invia una notifica email (richiede mailutils installato)
send_notification() {
    local subject="$1"
    local body="$2"

    if command -v mail &> /dev/null; then
        echo "$body" | mail -s "$subject" "$EMAIL_ALERT"
        log "INFO" "Notifica email inviata a $EMAIL_ALERT"
    else
        log "WARN" "mail non trovato — notifica email non inviata"
    fi
}

# Verifica che tutti i programmi necessari siano installati
check_dependencies() {
    local deps=("tar" "gzip" "md5sum" "rsync" "df")

    log "INFO" "Verifica dipendenze in corso..."

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "ERROR" "Dipendenza mancante: $dep — installazione richiesta"
            exit 1
        fi
    done

    log "INFO" "${GREEN}Tutte le dipendenze sono presenti.${NC}"
}

# Controlla che lo spazio su disco sia sufficiente (minimo 20% libero)
check_disk_space() {
    local usage
    usage=$(df "$BACKUP_DEST" | awk 'NR==2 {print $5}' | tr -d '%')

    if [[ "$usage" -gt 80 ]]; then
        log "WARN" "${YELLOW}Spazio su disco critico: ${usage}% utilizzato${NC}"
        send_notification \
            "[ATTENZIONE] Spazio disco al ${usage}% — $(hostname)" \
            "Il disco di backup è all'${usage}%. Libera spazio al più presto."
    else
        log "INFO" "Spazio su disco: ${usage}% utilizzato — OK"
    fi
}

# Crea il backup compresso con timestamp nel nome
create_backup() {
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="${BACKUP_PREFIX}_${timestamp}.tar.gz"
    local backup_path="${BACKUP_DEST}/${backup_name}"

    log "INFO" "${BLUE}Avvio backup: ${backup_name}${NC}"

    # Crea la cartella di destinazione se non esiste
    mkdir -p "$BACKUP_DEST"

    # Esegue la compressione escludendo file temporanei e cache
    if tar \
        --exclude='*.tmp' \
        --exclude='*.cache' \
        --exclude='node_modules' \
        --exclude='.git' \
        -czf "$backup_path" \
        "$BACKUP_SOURCE" 2>> "$LOG_FILE"; then

        log "INFO" "${GREEN}Backup creato con successo: ${backup_path}${NC}"
        echo "$backup_path"  # Restituisce il percorso per le funzioni successive

    else
        log "ERROR" "${RED}ERRORE durante la creazione del backup!${NC}"
        send_notification \
            "[ERRORE] Backup fallito — $(hostname) — $(date)" \
            "Il backup del $(date) è fallito. Controlla il log: $LOG_FILE"
        exit 1
    fi
}

# Verifica l'integrità del backup tramite checksum MD5
verify_backup() {
    local backup_path="$1"
    local checksum_file="${backup_path}.md5"

    log "INFO" "Verifica integrità in corso..."

    # Genera il checksum del file di backup
    md5sum "$backup_path" > "$checksum_file"

    # Verifica che il checksum corrisponda
    if md5sum --check "$checksum_file" &> /dev/null; then
        local checksum
        checksum=$(awk '{print $1}' "$checksum_file")
        log "INFO" "${GREEN}Integrità verificata. Checksum MD5: ${checksum}${NC}"
    else
        log "ERROR" "${RED}ERRORE: il backup è corrotto! Checksum non valido.${NC}"
        send_notification \
            "[ERRORE CRITICO] Backup corrotto — $(hostname)" \
            "Il backup ${backup_path} ha fallito la verifica di integrità."
        exit 1
    fi
}

# Copia il backup sul server remoto tramite rsync+SSH
sync_to_remote() {
    local backup_path="$1"

    log "INFO" "Sincronizzazione su server remoto in corso..."

    if rsync \
        --archive \
        --compress \
        --progress \
        --checksum \
        "$backup_path" \
        "${backup_path}.md5" \
        "$REMOTE_DEST" 2>> "$LOG_FILE"; then

        log "INFO" "${GREEN}Sincronizzazione remota completata.${NC}"
    else
        log "WARN" "${YELLOW}Sincronizzazione remota fallita — backup locale conservato.${NC}"
        send_notification \
            "[ATTENZIONE] Sync remoto fallito — $(hostname)" \
            "Il backup locale è integro, ma la sincronizzazione remota ha fallito."
    fi
}

# Elimina i backup più vecchi del numero di giorni configurato
rotate_old_backups() {
    log "INFO" "Rotazione backup: eliminazione file più vecchi di ${RETENTION_DAYS} giorni..."

    local count=0

    # Trova e rimuove i backup scaduti
    while IFS= read -r -d '' old_backup; do
        rm -f "$old_backup" "${old_backup}.md5"
        log "INFO" "Eliminato: $(basename "$old_backup")"
        ((count++))
    done < <(find "$BACKUP_DEST" -name "${BACKUP_PREFIX}_*.tar.gz" \
             -mtime "+${RETENTION_DAYS}" -print0)

    if [[ "$count" -eq 0 ]]; then
        log "INFO" "Nessun backup scaduto da eliminare."
    else
        log "INFO" "${GREEN}${count} backup scaduti eliminati.${NC}"
    fi
}

# Genera il report finale e invia la notifica di successo
generate_report() {
    local backup_path="$1"
    local start_time="$2"
    local end_time
    end_time=$(date '+%Y-%m-%d %H:%M:%S')

    local backup_size
    backup_size=$(du -sh "$backup_path" | awk '{print $1}')

    local total_backups
    total_backups=$(find "$BACKUP_DEST" -name "${BACKUP_PREFIX}_*.tar.gz" | wc -l)

    local report
    report="
=== REPORT BACKUP COMPLETATO ===
Data:              $(date '+%d/%m/%Y')
Inizio:            ${start_time}
Fine:              ${end_time}
File:              $(basename "$backup_path")
Dimensione:        ${backup_size}
Backup totali:     ${total_backups} (ultimi ${RETENTION_DAYS} giorni)
Server:            $(hostname)
Stato:             ✅ SUCCESSO
================================"

    log "INFO" "$report"

    send_notification \
        "[OK] Backup completato — $(hostname) — $(date '+%d/%m/%Y')" \
        "$report"
}

# =============================================================================
# ESECUZIONE PRINCIPALE
# =============================================================================

main() {
    local start_time
    start_time=$(date '+%Y-%m-%d %H:%M:%S')

    log "INFO" "=============================================="
    log "INFO" "  AVVIO BACKUP AUTOMATICO — $(hostname)"
    log "INFO" "  $(date '+%d/%m/%Y %H:%M:%S')"
    log "INFO" "=============================================="

    # Step 1: Verifica che tutti i tool necessari siano presenti
    check_dependencies

    # Step 2: Controlla lo spazio su disco prima di procedere
    check_disk_space

    # Step 3: Crea il backup compresso
    local backup_path
    backup_path=$(create_backup)

    # Step 4: Verifica che il backup non sia corrotto
    verify_backup "$backup_path"

    # Step 5: Copia il backup sul server remoto
    sync_to_remote "$backup_path"

    # Step 6: Elimina i backup più vecchi di 30 giorni
    rotate_old_backups

    # Step 7: Genera il report e notifica il successo
    generate_report "$backup_path" "$start_time"

    log "INFO" "=============================================="
    log "INFO" "  BACKUP COMPLETATO CON SUCCESSO ✅"
    log "INFO" "=============================================="
}

# Punto di ingresso
main "$@"
