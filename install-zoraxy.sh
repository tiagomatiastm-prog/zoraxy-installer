#!/bin/bash

#########################################
# Script d'installation de Zoraxy
# Reverse Proxy moderne pour Debian 13
# Auteur: Tiago Matias
# Repository: https://github.com/tiagomatiastm-prog/zoraxy-installer
# Dernière mise à jour: 2025-11-05
#########################################

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables par défaut
ZORAXY_VERSION="latest"
INSTALL_DIR="/opt/zoraxy"
DATA_DIR="/opt/zoraxy/data"
MGMT_PORT="8000"
WEB_PORT_HTTP="80"
WEB_PORT_HTTPS="443"
ZORAXY_USER="zoraxy"
ADMIN_PASSWORD=""

# Détection de l'architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        BINARY_NAME="zoraxy_linux_amd64"
        ;;
    aarch64)
        BINARY_NAME="zoraxy_linux_arm64"
        ;;
    armv7l|armv6l)
        BINARY_NAME="zoraxy_linux_arm"
        ;;
    riscv64)
        BINARY_NAME="zoraxy_linux_riscv64"
        ;;
    *)
        echo -e "${RED}Architecture non supportée: $ARCH${NC}"
        exit 1
        ;;
esac

# Fonction pour afficher les messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour générer un mot de passe aléatoire
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Vérifier si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Vérifier la distribution
if [ ! -f /etc/debian_version ]; then
    log_error "Ce script est conçu pour Debian 13"
    exit 1
fi

log_info "Début de l'installation de Zoraxy..."
log_info "Architecture détectée: $ARCH ($BINARY_NAME)"

# Mise à jour du système
log_info "Mise à jour du système..."
apt-get update
apt-get upgrade -y

# Installation des dépendances
log_info "Installation des dépendances..."
apt-get install -y wget curl sudo

# Création de l'utilisateur système
log_info "Création de l'utilisateur système 'zoraxy'..."
if ! id -u "$ZORAXY_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/false -d "$INSTALL_DIR" "$ZORAXY_USER"
    log_success "Utilisateur 'zoraxy' créé"
else
    log_warning "Utilisateur 'zoraxy' existe déjà"
fi

# Création des répertoires
log_info "Création des répertoires..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$DATA_DIR/config"
mkdir -p "$DATA_DIR/certs"
mkdir -p "$DATA_DIR/log"

# Téléchargement de Zoraxy
log_info "Téléchargement de Zoraxy (version $ZORAXY_VERSION)..."
cd "$INSTALL_DIR"
wget -q --show-progress "https://github.com/tobychui/zoraxy/releases/latest/download/$BINARY_NAME" -O zoraxy
chmod +x zoraxy
log_success "Zoraxy téléchargé avec succès"

# Génération du mot de passe administrateur
ADMIN_PASSWORD=$(generate_password)
log_info "Mot de passe administrateur généré"

# Création du service systemd
log_info "Création du service systemd..."
cat > /etc/systemd/system/zoraxy.service << EOF
[Unit]
Description=Zoraxy Reverse Proxy Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$ZORAXY_USER
Group=$ZORAXY_USER
WorkingDirectory=$DATA_DIR
ExecStart=$INSTALL_DIR/zoraxy -port=:$MGMT_PORT
Restart=always
RestartSec=5

# Sécurité
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$DATA_DIR
AmbientCapabilities=CAP_NET_BIND_SERVICE

# Limites de ressources
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Configuration des permissions
log_info "Configuration des permissions..."
chown -R "$ZORAXY_USER:$ZORAXY_USER" "$INSTALL_DIR"
chown -R "$ZORAXY_USER:$ZORAXY_USER" "$DATA_DIR"
chmod 755 "$INSTALL_DIR"
chmod 755 "$DATA_DIR"

# Activation et démarrage du service
log_info "Activation et démarrage du service Zoraxy..."
systemctl daemon-reload
systemctl enable zoraxy.service
systemctl start zoraxy.service

# Attente du démarrage du service
sleep 3

# Vérification du statut
if systemctl is-active --quiet zoraxy.service; then
    log_success "Service Zoraxy démarré avec succès"
else
    log_error "Échec du démarrage du service Zoraxy"
    systemctl status zoraxy.service
    exit 1
fi

# Récupération de l'adresse IP
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Création du fichier d'informations
INFO_FILE="/root/zoraxy-info.txt"
log_info "Création du fichier d'informations..."
cat > "$INFO_FILE" << EOF
=====================================
   ZORAXY - Informations d'installation
=====================================

Date d'installation : $(date '+%Y-%m-%d %H:%M:%S')
Version : $ZORAXY_VERSION
Architecture : $ARCH

ACCÈS WEB
---------
Interface de gestion : http://$IP_ADDRESS:$MGMT_PORT
                       http://localhost:$MGMT_PORT

PREMIÈRE CONNEXION
------------------
Lors de votre première connexion, Zoraxy vous demandera de créer
un compte administrateur. Utilisez les informations suivantes :

Username : admin
Password : $ADMIN_PASSWORD

⚠️  IMPORTANT : Changez ce mot de passe après votre première connexion !

PORTS UTILISÉS
--------------
Port de gestion : $MGMT_PORT (interface web)
Port HTTP : $WEB_PORT_HTTP (proxy)
Port HTTPS : $WEB_PORT_HTTPS (proxy avec SSL/TLS)

CHEMINS IMPORTANTS
------------------
Installation : $INSTALL_DIR
Données : $DATA_DIR
Configuration : $DATA_DIR/config
Certificats : $DATA_DIR/certs
Logs : $DATA_DIR/log

COMMANDES UTILES
----------------
Statut du service :    systemctl status zoraxy
Arrêter le service :   systemctl stop zoraxy
Démarrer le service :  systemctl start zoraxy
Redémarrer le service : systemctl restart zoraxy
Voir les logs :        journalctl -u zoraxy -f

FONCTIONNALITÉS
---------------
- Reverse proxy HTTP/HTTPS
- Gestion automatique des certificats SSL (Let's Encrypt / ACME)
- Interface web intuitive
- GeoIP blocking
- Rate limiting
- WebDAV support
- Redirections et rewrites
- Load balancing
- Health checks

DOCUMENTATION
-------------
GitHub : https://github.com/tobychui/zoraxy
Documentation : https://zoraxy.aroz.org/

=====================================
EOF

chmod 600 "$INFO_FILE"
log_success "Fichier d'informations créé : $INFO_FILE"

# Affichage des informations finales
echo ""
log_success "═══════════════════════════════════════════════════════════════"
log_success "  Installation de Zoraxy terminée avec succès !"
log_success "═══════════════════════════════════════════════════════════════"
echo ""
log_info "Interface de gestion : ${GREEN}http://$IP_ADDRESS:$MGMT_PORT${NC}"
echo ""
log_warning "Première connexion :"
echo -e "  Username: ${YELLOW}admin${NC}"
echo -e "  Password: ${YELLOW}$ADMIN_PASSWORD${NC}"
echo ""
log_warning "⚠️  Changez le mot de passe après votre première connexion !"
echo ""
log_info "Toutes les informations sont sauvegardées dans : ${GREEN}$INFO_FILE${NC}"
echo ""
log_info "Pour voir les logs : ${BLUE}journalctl -u zoraxy -f${NC}"
log_info "Pour vérifier le statut : ${BLUE}systemctl status zoraxy${NC}"
echo ""
log_success "═══════════════════════════════════════════════════════════════"
