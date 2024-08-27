#!/bin/bash

sudo apt update -y
sudo apt upgrade -y
sudo apt install qemu-guest-agent -y

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl settings
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Configure apt for Kubernetes
sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# Install Kubernetes components
sudo apt install -y kubelet=1.28.2-1.1 kubeadm=1.28.2-1.1 kubectl=1.28.2-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Install containerd
VERSION="1.7.2"
wget https://github.com/containerd/containerd/releases/download/v${VERSION}/containerd-${VERSION}-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-${VERSION}-linux-amd64.tar.gz

# Download and install the systemd service file
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /etc/systemd/system/

# Download and install runc
RVERSION="1.1.7"
wget https://github.com/opencontainers/runc/releases/download/v${RVERSION}/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

sudo mkdir /etc/containerd

# Configure containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd.service

# Restart and enable kubelet
sudo systemctl restart kubelet.service
sudo systemctl enable kubelet.service
