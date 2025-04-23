#!/bin/bash

# Emplacement du fichier de sauvegarde
if [[ -z "$1" ]]; then
    echo "Erreur: le paramètre du chemin du fichier de sauvegarde (tar de configuration) est nécessaire en guise de premier parametre du script."
    exit 1
fi

BACKUP_PATH=$1

# Vérification que le fichier de sauvegarde existe
if [[ ! -f "$BACKUP_PATH" ]]; then
    echo "Le fichier de sauvegarde n'existe pas à l'emplacement spécifié: $BACKUP_PATH"
    exit 1
fi

# Dossier cible pour la restauration
TARGET_DIRS=("/etc/pve" "/etc/network" "/etc/hosts" "/etc/hostname")

# Extraire le tarball dans un répertoire temporaire
TEMP_DIR=$(mktemp -d)
echo "Extraction du tarball dans $TEMP_DIR..."
tar -xzf "$BACKUP_PATH" -C "$TEMP_DIR"
if [[ $? -ne 0 ]]; then
    echo "Erreur lors de l'extraction du tarball."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Restauration des fichiers de configuration
for DIR in "${TARGET_DIRS[@]}"; do
    if [[ -d "$TEMP_DIR$(dirname $DIR)" ]]; then
        echo "Restauration de la configuration : $DIR"
        cp -r "$TEMP_DIR$(dirname $DIR)"/* "$DIR"
        if [[ $? -ne 0 ]]; then
            echo "Erreur lors de la copie des fichiers vers $DIR."
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        echo "Aucun fichier à restaurer pour $DIR"
    fi
done

# Nettoyage du répertoire temporaire
rm -rf "$TEMP_DIR"

# Recréation du dossier /backup
mkdir -p /backup

# Ajout de la tâche cron pour la sauvegarde automatique
CRON_JOB="0 2 * * * tar -czf /backup/config_cluster_\$(date +\%F).tar.gz /etc/pve /etc/network/interfaces /etc/hosts /etc/hostname"
(crontab -l | grep -q -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# Redémarrage des services nécessaires (si besoin)
systemctl restart pve-cluster
systemctl restart pvedaemon

echo "Restauration terminée avec succès."