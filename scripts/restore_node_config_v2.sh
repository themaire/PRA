#!/bin/bash

# Script de restauration de configuration Proxmox VE - Version 2
# Auteur: PRA Recovery Script
# Date: $(date +%Y-%m-%d)

# Configuration des logs
LOG_FILE="/var/log/proxmox_restore.log"
BACKUP_DIR="/backup"

# Fonction de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Fonction de sauvegarde préventive de la configuration actuelle
backup_current_config() {
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local current_backup="/tmp/config_backup_before_restore_$backup_date.tar.gz"
    
    log "Sauvegarde préventive de la configuration actuelle..."
    tar -czf "$current_backup" \
        /etc/pve /etc/network/interfaces /etc/hosts /etc/hostname 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log "Configuration actuelle sauvegardée dans $current_backup"
        echo "IMPORTANT: Configuration actuelle sauvegardée dans $current_backup"
    else
        log "ATTENTION: Impossible de sauvegarder la configuration actuelle"
    fi
}

# Fonction de validation du tarball
validate_tarball() {
    local tarball_path=$1
    
    log "Validation du contenu du tarball..."
    echo "Contenu du tarball:"
    tar -tzf "$tarball_path" | head -20
    
    # Vérification que les dossiers critiques sont présents
    local required_paths=("etc/pve" "etc/network" "etc/hosts" "etc/hostname")
    local missing_paths=()
    
    for path in "${required_paths[@]}"; do
        if ! tar -tzf "$tarball_path" | grep -q "^$path" 2>/dev/null; then
            missing_paths+=("$path")
        fi
    done
    
    if [[ ${#missing_paths[@]} -gt 0 ]]; then
        log "ATTENTION: Chemins manquants dans le tarball: ${missing_paths[*]}"
        echo "ATTENTION: Les chemins suivants sont manquants dans le tarball:"
        printf '%s\n' "${missing_paths[@]}"
        echo ""
        read -p "Voulez-vous continuer malgré tout ? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Restauration annulée par l'utilisateur"
            exit 1
        fi
    else
        log "Validation du tarball réussie - tous les chemins requis sont présents"
    fi
}

# Fonction principale
main() {
    log "=== DÉBUT DE LA RESTAURATION PROXMOX VE ==="
    
    # Vérification des paramètres
    if [[ -z "$1" ]]; then
        echo "Erreur: le paramètre du chemin du fichier de sauvegarde (tar de configuration) est nécessaire."
        echo "Usage: $0 <chemin_vers_fichier_backup.tar.gz>"
        exit 1
    fi

    BACKUP_PATH=$1

    # Vérification que le fichier de sauvegarde existe
    if [[ ! -f "$BACKUP_PATH" ]]; then
        log "ERREUR: Le fichier de sauvegarde n'existe pas à l'emplacement spécifié: $BACKUP_PATH"
        exit 1
    fi

    log "Fichier de sauvegarde trouvé: $BACKUP_PATH"

    # Validation du tarball
    validate_tarball "$BACKUP_PATH"

    # Sauvegarde préventive
    backup_current_config

    # Confirmation avant restauration
    echo ""
    echo "ATTENTION: Cette opération va remplacer la configuration Proxmox actuelle."
    read -p "Êtes-vous sûr de vouloir continuer ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Restauration annulée par l'utilisateur"
        exit 0
    fi

    # Dossiers cibles pour la restauration
    TARGET_DIRS=("/etc/pve" "/etc/network" "/etc/hosts" "/etc/hostname")

    # Extraire le tarball dans un répertoire temporaire
    TEMP_DIR=$(mktemp -d)
    log "Extraction du tarball dans $TEMP_DIR..."
    
    tar -xzf "$BACKUP_PATH" -C "$TEMP_DIR"
    if [[ $? -ne 0 ]]; then
        log "ERREUR: Échec de l'extraction du tarball"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    log "Extraction réussie"

    # Restauration des fichiers de configuration
    for TARGET in "${TARGET_DIRS[@]}"; do
        SOURCE_PATH="$TEMP_DIR$TARGET"
        
        if [[ -e "$SOURCE_PATH" ]]; then
            log "Restauration de la configuration : $TARGET"
            
            # Créer le répertoire parent si nécessaire
            mkdir -p "$(dirname "$TARGET")"
            
            # Copier les fichiers en préservant les permissions et propriétaires
            if [[ -d "$SOURCE_PATH" ]]; then
                # Si c'est un dossier, copier tout son contenu
                cp -rp "$SOURCE_PATH"/* "$TARGET/" 2>/dev/null
            else
                # Si c'est un fichier, le copier directement
                cp -p "$SOURCE_PATH" "$TARGET"
            fi
            
            if [[ $? -eq 0 ]]; then
                log "✓ Restauration réussie pour $TARGET"
            else
                log "✗ ERREUR lors de la restauration de $TARGET"
                rm -rf "$TEMP_DIR"
                exit 1
            fi
        else
            log "⚠ Aucun fichier à restaurer pour $TARGET (non présent dans la sauvegarde)"
        fi
    done

    # Nettoyage du répertoire temporaire
    log "Nettoyage du répertoire temporaire..."
    rm -rf "$TEMP_DIR"

    # Création du dossier /backup si nécessaire
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log "Création du dossier $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
    fi

    # Configuration de la tâche cron pour les sauvegardes automatiques
    log "Configuration de la sauvegarde automatique..."
    CRON_JOB="0 2 * * * tar -czf $BACKUP_DIR/config_cluster_\$(date +\%F).tar.gz /etc/pve /etc/network/interfaces /etc/hosts /etc/hostname 2>/dev/null"
    
    # Vérifier si la tâche cron existe déjà
    if ! (crontab -l 2>/dev/null | grep -q -F "config_cluster_"); then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        log "✓ Tâche cron de sauvegarde automatique ajoutée"
    else
        log "ℹ Tâche cron de sauvegarde automatique déjà présente"
    fi

    # Redémarrage des services nécessaires
    log "Redémarrage des services Proxmox..."
    
    systemctl restart pve-cluster
    if [[ $? -eq 0 ]]; then
        log "✓ Service pve-cluster redémarré avec succès"
    else
        log "✗ ERREUR lors du redémarrage de pve-cluster"
    fi
    
    # Attendre un peu avant de redémarrer le daemon
    sleep 5
    
    systemctl restart pvedaemon
    if [[ $? -eq 0 ]]; then
        log "✓ Service pvedaemon redémarré avec succès"
    else
        log "✗ ERREUR lors du redémarrage de pvedaemon"
    fi

    # Vérification de l'état des services
    log "Vérification de l'état des services..."
    sleep 10
    
    if systemctl is-active --quiet pve-cluster; then
        log "✓ Service pve-cluster actif"
    else
        log "⚠ ATTENTION: Service pve-cluster non actif"
    fi
    
    if systemctl is-active --quiet pvedaemon; then
        log "✓ Service pvedaemon actif"
    else
        log "⚠ ATTENTION: Service pvedaemon non actif"
    fi

    # Affichage des informations post-restauration
    echo ""
    echo "=== RESTAURATION TERMINÉE ==="
    echo "Log complet disponible dans: $LOG_FILE"
    echo ""
    echo "ÉTAPES RECOMMANDÉES APRÈS LA RESTAURATION:"
    echo "1. Vérifiez la connectivité réseau"
    echo "2. Connectez-vous à l'interface web Proxmox"
    echo "3. Vérifiez que le cluster est fonctionnel (si applicable)"
    echo "4. Testez la création/gestion des VMs"
    echo "5. Vérifiez les certificats SSL/TLS"
    echo ""
    echo "En cas de problème, la configuration précédente peut être restaurée depuis:"
    echo "$(ls -t /tmp/config_backup_before_restore_*.tar.gz 2>/dev/null | head -1)"
    
    log "=== RESTAURATION TERMINÉE AVEC SUCCÈS ==="
}

# Vérification que le script est exécuté en tant que root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root (utilisez sudo)"
    exit 1
fi

# Lancement de la fonction principale
main "$@"