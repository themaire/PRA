# Script de Restauration de Configuration de Node Proxmox

Ce repository contient un script Bash pour restaurer les configurations de node Proxmox à partir d'un fichier de sauvegarde tarball.

A la fin du script `scripts/restore_node_config.sh`, la création des fichiers de sauvegarde est redéfini dans le crontab.

## Contenu

- `scripts/restore_node_config.sh`: Script principal pour restaurer les configurations.

## Utilisation

0. Faire une clean install de Proxmox

1. Cloner le repository :
    ```sh
    git clone <URL_DU_REPOSITORY>
    cd <NOM_DU_REPOSITORY>
    ```

2. cd dans le dossier cloné et rendre le script exécutable :
    ```sh
    chmod +x scripts/restore_node_config.sh
    ```

3. Exécuter le script avec le chemin du fichier de sauvegarde en paramètre que vous aurez pris soin de copier dans la machine :
    ```sh
    sudo ./restore_node_config.sh /backup/le_fichier_de_sauvegarde.tar.gz
    ```

## Fonctionnalités

- Vérifie l'existence du fichier de sauvegarde.
- Extrait le contenu du fichier tarball dans un répertoire temporaire.
- Copie les fichiers de configuration dans les répertoires cibles (`/etc/pve`, `/etc/network`, `/etc/hosts`, `/etc/hostname`).
- Nettoie le répertoire temporaire après la restauration.
- Crée un dossier `/backup` si nécessaire.
- Ajoute une tâche cron pour effectuer des sauvegardes automatiques quotidiennes à 2h du matin.
- Redémarre les services nécessaires (`pve-cluster`, `pvedaemon`).

## Avertissement

Utilisez ce script avec précaution. Assurez-vous d'avoir des sauvegardes valides avant de procéder à la restauration.

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.