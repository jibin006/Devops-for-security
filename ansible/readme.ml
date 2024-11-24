# Ansible Practice on GCP: Setting Up and Running Playbooks

This guide walks you through setting up Ansible on a GCP instance and running your first playbook.

---

## Prerequisites
- **Google Cloud SDK** installed and authenticated.
- **Basic familiarity** with Linux commands and Ansible concepts.

---

## Steps

### 1. Install Ansible
Update your system and install Ansible:
```bash
sudo apt update
sudo apt install ansible -y
```

### 2. Configure Your GCP Project
Replace `airy-adapter-439306-c6` with your actual project ID:
```bash
gcloud config set project airy-adapter-439306-c6
```

### 3. Verify Ansible Installation
Ensure Ansible is correctly installed:
```bash
ansible --version
```

### 4. Create a VM Instance on GCP
Use the following command to create a VM instance:
```bash
gcloud compute instances create ansible-test \
    --machine-type=e2-micro \
    --zone=us-central1-a \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --tags=http-server
```

### 5. Set Up Your Workspace
Create and navigate to a workspace directory:
```bash
mkdir ansible-practice
cd ansible-practice
```

### 6. Generate SSH Keys
Generate an SSH key for accessing the VM:
```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/gcp_key -N ""
cat ~/.ssh/gcp_key.pub
```

Add the SSH public key to the instance metadata:
```bash
gcloud compute instances add-metadata ansible-test \
    --zone=us-central1-a \
    --metadata=ssh-keys="jibinbenny06:$(cat ~/.ssh/gcp_key.pub)"
```

Verify the metadata:
```bash
gcloud compute instances describe ansible-test \
    --zone=us-central1-a \
    --format="get(metadata.ssh-keys)"
```

### 7. Test SSH Connectivity
Connect to the VM using SSH:
```bash
ssh -i ~/.ssh/gcp_key jibinbenny06@<VM_EXTERNAL_IP>
```
Replace `<VM_EXTERNAL_IP>` with the external IP of your VM.

---

## Setting Up Ansible Inventory

### 1. Create an Inventory File
Create a new file named `inventory.ini`:
```bash
nano inventory.ini
```

Add the following content:
```
[gcp_servers]
ansible-test ansible_host=<VM_EXTERNAL_IP>

[all:vars]
ansible_user=jibinbenny06
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=~/.ssh/gcp_key
```

Alternatively, use a single command to create the file:
```bash
cat << 'EOF' > inventory.ini
[gcp_servers]
ansible-test ansible_host=<VM_EXTERNAL_IP>

[all:vars]
ansible_user=jibinbenny06
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=~/.ssh/gcp_key
EOF
```

Replace `<VM_EXTERNAL_IP>` with the external IP of your VM.

Verify the file:
```bash
cat inventory.ini
```

---

## Running Your First Playbook

1. Use the following command to run your playbook:
```bash
ansible-playbook -i inventory.ini first-playbook.yml
```

---

Feel free to customize the steps and settings to fit your use case. Happy learning with Ansible! 🎉
