# Déploiement automatisé avec Ansible

Ce guide explique comment déployer Zoraxy sur plusieurs serveurs Debian 13 en utilisant Ansible.

## 📋 Prérequis

Sur la machine de contrôle Ansible :
- Ansible 2.9+ installé
- Accès SSH configuré vers les serveurs cibles
- Clés SSH configurées (sans mot de passe)

Sur les serveurs cibles :
- Debian 13
- Accès root ou sudo
- Python 3 installé

## 📂 Structure des fichiers

```
ansible-deployment/
├── inventory.ini          # Inventaire des serveurs
├── deploy-zoraxy.yml      # Playbook principal
└── group_vars/
    └── all.yml            # Variables globales
```

## 🔧 Configuration

### 1. Créer l'inventaire

Créez le fichier `inventory.ini` :

```ini
[zoraxy_servers]
server1 ansible_host=192.168.1.10 ansible_user=root
server2 ansible_host=192.168.1.11 ansible_user=root
server3 ansible_host=192.168.1.12 ansible_user=debian ansible_become=yes

[zoraxy_servers:vars]
ansible_python_interpreter=/usr/bin/python3
```

### 2. Créer les variables (optionnel)

Créez `group_vars/all.yml` pour personnaliser l'installation :

```yaml
---
# Variables pour l'installation de Zoraxy
zoraxy_mgmt_port: 8000
zoraxy_http_port: 80
zoraxy_https_port: 443
zoraxy_install_dir: /opt/zoraxy
zoraxy_data_dir: /opt/zoraxy/data
zoraxy_user: zoraxy
```

### 3. Créer le playbook

Créez `deploy-zoraxy.yml` :

```yaml
---
- name: Deploy Zoraxy Reverse Proxy
  hosts: zoraxy_servers
  become: yes
  gather_facts: yes

  vars:
    zoraxy_mgmt_port: "{{ zoraxy_mgmt_port | default('8000') }}"
    zoraxy_http_port: "{{ zoraxy_http_port | default('80') }}"
    zoraxy_https_port: "{{ zoraxy_https_port | default('443') }}"

  tasks:
    - name: Check if running Debian 13
      assert:
        that:
          - ansible_distribution == "Debian"
          - ansible_distribution_major_version == "13"
        fail_msg: "This playbook requires Debian 13"

    - name: Download Zoraxy installation script
      get_url:
        url: https://raw.githubusercontent.com/tiagomatiastm-prog/zoraxy-installer/master/install-zoraxy.sh
        dest: /tmp/install-zoraxy.sh
        mode: '0755'

    - name: Execute Zoraxy installation script
      command: /tmp/install-zoraxy.sh
      args:
        creates: /opt/zoraxy/zoraxy
      register: installation_result

    - name: Wait for Zoraxy service to be active
      systemd:
        name: zoraxy
        state: started
      register: service_status
      retries: 5
      delay: 3
      until: service_status.status.ActiveState == "active"

    - name: Get Zoraxy installation info
      slurp:
        src: /root/zoraxy-info.txt
      register: zoraxy_info

    - name: Display installation info
      debug:
        msg: "{{ zoraxy_info['content'] | b64decode }}"

    - name: Save installation info locally
      copy:
        content: "{{ zoraxy_info['content'] | b64decode }}"
        dest: "./zoraxy-info-{{ inventory_hostname }}.txt"
      delegate_to: localhost
      become: no

    - name: Verify Zoraxy is responding
      uri:
        url: "http://localhost:{{ zoraxy_mgmt_port }}"
        status_code: 200
      register: health_check
      retries: 3
      delay: 5

    - name: Display access information
      debug:
        msg:
          - "Zoraxy deployed successfully on {{ inventory_hostname }}"
          - "Management interface: http://{{ ansible_default_ipv4.address }}:{{ zoraxy_mgmt_port }}"
          - "Check ./zoraxy-info-{{ inventory_hostname }}.txt for credentials"
```

## 🚀 Déploiement

### Vérifier la connectivité

```bash
ansible -i inventory.ini zoraxy_servers -m ping
```

### Tester le playbook (dry-run)

```bash
ansible-playbook -i inventory.ini deploy-zoraxy.yml --check
```

### Déployer sur tous les serveurs

```bash
ansible-playbook -i inventory.ini deploy-zoraxy.yml
```

### Déployer sur un serveur spécifique

```bash
ansible-playbook -i inventory.ini deploy-zoraxy.yml --limit server1
```

### Déployer avec verbosité

```bash
ansible-playbook -i inventory.ini deploy-zoraxy.yml -vv
```

## 📊 Vérification post-déploiement

### Vérifier le statut des services

```bash
ansible -i inventory.ini zoraxy_servers -m systemd -a "name=zoraxy state=started" -b
```

### Vérifier les ports ouverts

```bash
ansible -i inventory.ini zoraxy_servers -m shell -a "ss -tlnp | grep zoraxy" -b
```

### Récupérer les logs

```bash
ansible -i inventory.ini zoraxy_servers -m shell -a "journalctl -u zoraxy -n 20" -b
```

### Récupérer les fichiers d'info

```bash
ansible -i inventory.ini zoraxy_servers -m fetch \
  -a "src=/root/zoraxy-info.txt dest=./zoraxy-info-{{ inventory_hostname }}.txt flat=yes" -b
```

## 🔄 Playbook de mise à jour

Pour mettre à jour Zoraxy sur tous les serveurs, créez `update-zoraxy.yml` :

```yaml
---
- name: Update Zoraxy
  hosts: zoraxy_servers
  become: yes

  tasks:
    - name: Stop Zoraxy service
      systemd:
        name: zoraxy
        state: stopped

    - name: Backup current binary
      copy:
        src: /opt/zoraxy/zoraxy
        dest: /opt/zoraxy/zoraxy.backup
        remote_src: yes

    - name: Detect system architecture
      command: uname -m
      register: arch

    - name: Set binary name based on architecture
      set_fact:
        binary_name: >-
          {% if arch.stdout == 'x86_64' %}zoraxy_linux_amd64
          {% elif arch.stdout == 'aarch64' %}zoraxy_linux_arm64
          {% elif arch.stdout in ['armv7l', 'armv6l'] %}zoraxy_linux_arm
          {% elif arch.stdout == 'riscv64' %}zoraxy_linux_riscv64
          {% else %}zoraxy_linux_amd64
          {% endif %}

    - name: Download latest Zoraxy version
      get_url:
        url: "https://github.com/tobychui/zoraxy/releases/latest/download/{{ binary_name }}"
        dest: /opt/zoraxy/zoraxy
        mode: '0755'
        owner: zoraxy
        group: zoraxy

    - name: Start Zoraxy service
      systemd:
        name: zoraxy
        state: started

    - name: Verify service is running
      systemd:
        name: zoraxy
      register: service_status
      failed_when: service_status.status.ActiveState != "active"
```

Exécution :
```bash
ansible-playbook -i inventory.ini update-zoraxy.yml
```

## 🗑️ Playbook de désinstallation

Pour désinstaller Zoraxy, créez `uninstall-zoraxy.yml` :

```yaml
---
- name: Uninstall Zoraxy
  hosts: zoraxy_servers
  become: yes

  tasks:
    - name: Stop and disable Zoraxy service
      systemd:
        name: zoraxy
        state: stopped
        enabled: no
      ignore_errors: yes

    - name: Remove systemd service file
      file:
        path: /etc/systemd/system/zoraxy.service
        state: absent

    - name: Reload systemd
      systemd:
        daemon_reload: yes

    - name: Remove Zoraxy installation directory
      file:
        path: /opt/zoraxy
        state: absent

    - name: Remove Zoraxy user
      user:
        name: zoraxy
        state: absent
        remove: yes

    - name: Remove info file
      file:
        path: /root/zoraxy-info.txt
        state: absent

    - name: Display uninstallation complete message
      debug:
        msg: "Zoraxy has been uninstalled from {{ inventory_hostname }}"
```

## 🔐 Sécurité

### Utiliser un vault Ansible pour les secrets

Si vous voulez stocker des mots de passe :

```bash
ansible-vault create group_vars/vault.yml
```

Contenu :
```yaml
vault_zoraxy_admin_password: "VotreMotDePasseSécurisé"
```

Dans le playbook :
```yaml
vars:
  zoraxy_admin_password: "{{ vault_zoraxy_admin_password }}"
```

Exécution avec vault :
```bash
ansible-playbook -i inventory.ini deploy-zoraxy.yml --ask-vault-pass
```

## 📋 Checklist post-déploiement

- [ ] Tous les serveurs ont le service `zoraxy` actif
- [ ] Les interfaces web sont accessibles
- [ ] Les fichiers d'informations ont été récupérés
- [ ] Les mots de passe ont été changés
- [ ] Les ports 80/443/8000 sont ouverts dans le firewall si nécessaire
- [ ] Les certificats SSL sont configurés pour les domaines
- [ ] Les règles de proxy sont configurées

## 🐛 Dépannage

### Erreur de connexion SSH

```bash
# Tester la connexion
ansible -i inventory.ini server1 -m ping

# Utiliser une clé SSH spécifique
ansible-playbook -i inventory.ini deploy-zoraxy.yml --private-key=~/.ssh/id_rsa
```

### Erreur de permissions

```bash
# Vérifier sudo
ansible -i inventory.ini zoraxy_servers -m shell -a "whoami" -b

# Demander le mot de passe sudo
ansible-playbook -i inventory.ini deploy-zoraxy.yml --ask-become-pass
```

### Service ne démarre pas

```bash
# Vérifier les logs
ansible -i inventory.ini server1 -m shell -a "journalctl -u zoraxy -n 50" -b
```

## 📚 Ressources

- [Documentation Ansible](https://docs.ansible.com/)
- [Zoraxy GitHub](https://github.com/tobychui/zoraxy)
- [Best Practices Ansible](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

Pour toute question ou problème, ouvrez une issue sur le dépôt GitHub.
