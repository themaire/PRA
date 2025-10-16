# Scripts de Restauration de Configuration Proxmox VE - Plan de Reprise d'Activité (PRA)

Ce repository contient des scripts Bash pour restaurer les configurations de nœuds Proxmox VE à partir de fichiers de sauvegarde tarball, dans le cadre d'un plan de reprise d'activité complet.

## 🎯 Objectif

Permettre une restauration rapide et fiable d'un nœud Proxmox VE après un incident majeur, en restaurant automatiquement :
- La configuration du cluster Proxmox
- Les paramètres réseau
- Les fichiers système critiques
- La planification des sauvegardes automatiques

## 📁 Contenu

- `scripts/restore_node_config.sh`: Script original de restauration
- `scripts/restore_node_config_v2.sh`: **Script amélioré recommandé** avec fonctionnalités avancées

## 🚀 Guide d'utilisation

### Prérequis
- Installation propre de Proxmox VE sur le matériel cible
- Fichier de sauvegarde de configuration (`.tar.gz`) disponible
- Accès root au système

### Étapes de restauration

#### 1. Préparation initiale
```bash
# Installation propre de Proxmox VE
# (via ISO officiel Proxmox)
```

#### 2. Récupération du script
```bash
# Cloner le repository
git clone <URL_DU_REPOSITORY>
cd PRA

# OU télécharger directement le script
wget https://raw.githubusercontent.com/themaire/PRA/main/scripts/restore_node_config_v2.sh
```

#### 3. Préparation et exécution
```bash
# Rendre le script exécutable
chmod +x scripts/restore_node_config_v2.sh

# Copier votre fichier de sauvegarde sur le serveur
# (via scp, rsync, clé USB, etc.)

# Exécuter la restauration
sudo ./scripts/restore_node_config_v2.sh /path/to/your/backup.tar.gz
```

## ✨ Fonctionnalités de la version 2

### 🔍 **Validation et sécurité**
- Vérification de l'intégrité du fichier de sauvegarde
- Sauvegarde préventive de la configuration actuelle
- Validations multiples avant chaque opération critique
- Confirmations utilisateur pour éviter les erreurs

### 📊 **Monitoring et logs**
- Système de logs complet avec horodatage
- Sauvegarde dans `/var/log/proxmox_restore.log`
- Affichage en temps réel du processus
- Indicateurs visuels (✓, ✗, ⚠, ℹ)

### 🛠 **Gestion d'erreurs avancée**
- Vérification de l'état des services après redémarrage
- Codes de retour appropriés pour l'automatisation
- Messages d'erreur détaillés et contextuels
- Instructions de récupération en cas d'échec

### 🔄 **Processus optimisé**
- Préservation des permissions et propriétaires
- Gestion intelligente des dossiers vs fichiers
- Création automatique des répertoires manquants
- Nettoyage automatique des fichiers temporaires

## 📋 Contenu de la sauvegarde

Le script restaure les éléments suivants :
- `/etc/pve/` - Configuration du cluster Proxmox
- `/etc/network/interfaces` - Configuration réseau
- `/etc/hosts` - Table de résolution DNS locale
- `/etc/hostname` - Nom d'hôte du système

## ⚙️ Configuration automatique post-restauration

- **Dossier de sauvegarde** : Création de `/backup/` si nécessaire
- **Tâche cron** : Sauvegarde automatique quotidienne à 2h du matin
- **Services** : Redémarrage automatique de `pve-cluster` et `pvedaemon`
- **Vérifications** : Contrôle de l'état des services critiques

## 🔧 Utilisation avancée

### Test de la restauration
```bash
# Mode validation uniquement (recommandé pour les tests)
sudo ./scripts/restore_node_config_v2.sh --validate-only /backup/config.tar.gz
```

### Logs et diagnostic
```bash
# Consulter les logs de restauration
tail -f /var/log/proxmox_restore.log

# Vérifier l'état des services
systemctl status pve-cluster pvedaemon

# Lister les sauvegardes préventives
ls -la /tmp/config_backup_before_restore_*.tar.gz
```

## 📝 Checklist post-restauration

Après l'exécution du script, vérifiez :

- [ ] **Connectivité réseau** : `ping 8.8.8.8`
- [ ] **Interface web Proxmox** : Accès via https://IP:8006
- [ ] **État du cluster** : Vérification dans l'interface ou `pvecm status`
- [ ] **Services actifs** : `systemctl status pve-cluster pvedaemon`
- [ ] **Certificats SSL** : Vérification de la validité
- [ ] **Stockage** : Accès aux datastores configurés
- [ ] **Machines virtuelles** : Visibilité et fonctionnement
- [ ] **Sauvegardes Proxmox Backup Server** : Reconnexion automatique

## ⚠️ Avertissements importants

- **Testez toujours** la procédure sur un environnement de test avant la production
- **Documentez** vos spécificités réseau et cluster avant la sauvegarde
- **Vérifiez** la compatibilité des versions Proxmox entre sauvegarde et restauration
- **Sauvegardez** vos clés SSH et certificats personnalisés séparément

## 🆘 Récupération en cas d'échec

En cas de problème durant la restauration, le script crée automatiquement une sauvegarde préventive :

```bash
# Restaurer la configuration précédente
sudo tar -xzf /tmp/config_backup_before_restore_YYYYMMDD_HHMMSS.tar.gz -C /
sudo systemctl restart pve-cluster pvedaemon
```

## 🤝 Contribution

Les améliorations et suggestions sont les bienvenues ! N'hésitez pas à :
- Signaler des bugs ou problèmes
- Proposer des améliorations
- Partager vos retours d'expérience

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.