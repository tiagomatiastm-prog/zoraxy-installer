# Zoraxy Installer

Installation automatisée de **Zoraxy** - Reverse Proxy moderne et intuitif pour Debian 13.

## 🌟 Fonctionnalités

Zoraxy est un reverse proxy moderne écrit en Go, conçu pour simplifier la gestion de vos services web :

- ✅ **Interface web intuitive** - Gestion complète via une interface graphique moderne
- 🔒 **Certificats SSL automatiques** - Support Let's Encrypt / ACME intégré
- 🌍 **GeoIP blocking** - Blocage géographique des requêtes
- ⚡ **Rate limiting** - Protection contre les abus
- 🔄 **Load balancing** - Répartition de charge entre serveurs
- 📊 **Health checks** - Surveillance de l'état des backends
- 🗂️ **WebDAV support** - Serveur de fichiers intégré
- 🔀 **Redirections et rewrites** - Gestion avancée des URL
- 📈 **Statistiques en temps réel** - Monitoring intégré

## 📋 Prérequis

- **Système d'exploitation** : Debian 13
- **Architecture** : AMD64, ARM64, ARMv6/v7, RISC-V
- **Privilèges** : Accès root (sudo)
- **Ports** : 80, 443, 8000 (configurables)

## 🚀 Installation rapide

### Installation en une ligne

```bash
curl -fsSL https://raw.githubusercontent.com/tiagomatiastm-prog/zoraxy-installer/main/install-zoraxy.sh | sudo bash
```

### Installation manuelle

```bash
wget https://raw.githubusercontent.com/tiagomatiastm-prog/zoraxy-installer/main/install-zoraxy.sh
chmod +x install-zoraxy.sh
sudo ./install-zoraxy.sh
```

## 📦 Ce que fait le script

1. ✅ Détecte automatiquement l'architecture système
2. ✅ Installe les dépendances nécessaires
3. ✅ Télécharge la dernière version de Zoraxy
4. ✅ Crée un utilisateur système dédié (`zoraxy`)
5. ✅ Configure le service systemd
6. ✅ Génère un mot de passe administrateur sécurisé
7. ✅ Démarre et active le service
8. ✅ Crée un fichier d'informations dans `/root/zoraxy-info.txt`

## 🔐 Accès et configuration

Après l'installation, l'interface web est accessible sur :

```
http://VOTRE_IP:8000
```

**Première connexion** :
- Username : `admin`
- Password : *Voir le fichier `/root/zoraxy-info.txt`*

⚠️ **IMPORTANT** : Changez le mot de passe après votre première connexion !

## 🛠️ Gestion du service

```bash
# Voir le statut
systemctl status zoraxy

# Démarrer
systemctl start zoraxy

# Arrêter
systemctl stop zoraxy

# Redémarrer
systemctl restart zoraxy

# Voir les logs
journalctl -u zoraxy -f
```

## 📂 Structure des fichiers

```
/opt/zoraxy/           # Installation
├── zoraxy             # Binaire principal
└── data/              # Données persistantes
    ├── config/        # Configuration
    ├── certs/         # Certificats SSL
    └── log/           # Logs
```

## 🌐 Ports utilisés

| Port | Service | Description |
|------|---------|-------------|
| 8000 | Management | Interface web de gestion |
| 80 | HTTP | Reverse proxy HTTP |
| 443 | HTTPS | Reverse proxy HTTPS |

## 📚 Configuration d'un proxy

1. Connectez-vous à l'interface web
2. Allez dans **"Proxy"** → **"Add New Proxy"**
3. Configurez votre règle :
   - **Matching Rule** : Domaine ou chemin à matcher
   - **Upstream** : URL du service backend
   - **SSL** : Activez pour HTTPS automatique

Exemple de configuration :
```
Matching Rule: app.example.com
Upstream: http://localhost:3000
SSL: Enabled (Let's Encrypt)
```

## 🔒 Configuration SSL/TLS (Let's Encrypt)

Zoraxy intègre un client ACME pour générer automatiquement des certificats SSL :

1. Dans l'interface web, allez dans **"Certificates"**
2. Cliquez sur **"Request Certificate"**
3. Entrez votre domaine (doit pointer vers votre serveur)
4. Zoraxy gère automatiquement le renouvellement

## 🔥 Fonctionnalités avancées

### GeoIP Blocking
Bloquez ou autorisez des pays spécifiques :
- **Proxy Rules** → **GeoIP** → Sélectionnez les pays

### Rate Limiting
Protection contre les abus :
- **Proxy Rules** → **Rate Limit** → Configurez les limites

### Load Balancing
Répartissez la charge entre plusieurs backends :
- **Proxy Rules** → **Load Balance** → Ajoutez plusieurs upstreams

## 🆚 Comparaison avec d'autres solutions

| Fonctionnalité | Zoraxy | Nginx Proxy Manager | Traefik |
|----------------|--------|---------------------|---------|
| Interface Web | ✅ Moderne | ✅ Basique | ❌ |
| SSL Auto | ✅ | ✅ | ✅ |
| GeoIP | ✅ | ❌ | ⚠️ Plugin |
| Load Balancing | ✅ | ✅ | ✅ |
| Facilité | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

## 🐛 Dépannage

### Le service ne démarre pas
```bash
# Vérifier les logs
journalctl -u zoraxy -n 50

# Vérifier les permissions
ls -la /opt/zoraxy/data/
```

### Impossible d'accéder à l'interface
```bash
# Vérifier que le port est ouvert
ss -tlnp | grep 8000

# Vérifier le firewall
ufw status
```

### Problèmes de certificats SSL
- Assurez-vous que votre domaine pointe vers votre serveur
- Vérifiez que les ports 80 et 443 sont ouverts
- Consultez les logs : **Interface** → **Certificates** → **Logs**

## 📖 Documentation

- **Site officiel** : https://zoraxy.aroz.org/
- **GitHub** : https://github.com/tobychui/zoraxy
- **Documentation complète** : https://github.com/tobychui/zoraxy/wiki

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- 🐛 Signaler des bugs
- 💡 Proposer des améliorations
- 📝 Améliorer la documentation
- 🔧 Soumettre des pull requests

## 📝 Licence

Ce projet d'installation est sous licence MIT.

Zoraxy est sous licence AGPL-3.0 (voir https://github.com/tobychui/zoraxy)

## 👤 Auteur

**Tiago Matias**
- GitHub : [@tiagomatiastm-prog](https://github.com/tiagomatiastm-prog)

## ⭐ Support

Si ce projet vous a été utile, n'hésitez pas à lui donner une étoile sur GitHub !

---

**Note** : Ce script est conçu pour Debian 13. Pour d'autres distributions, des adaptations peuvent être nécessaires.
