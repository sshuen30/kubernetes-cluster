## Setting up Kubernetes-cluster
### 1) Do the following for master node and all workernodes

- Disable swap
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

- Setup hostname for master node and worker nodes
```bash
sudo hostnamectl set-hostname "master-node"
sudo hostnamectl set-hostname "worker-node-1"
```

- Update the /etc/hosts File for Hostname Resolution
```bash
sudo nao /etc/hosts
172.16.44.16 master-node
172.16.44.17 worker-node-1
```

- Set up the IPV4 bridge on all nodes
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```

- Update and install prerequisites
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
```

- Configure apt for Kubernetes 1.26 or 
```bash
sudo mkdir /etc/apt/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
```

- Configure apt for Kubernetes 1.29
```bash
sudo mkdir /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
```

- Install Kubernetes components 1.26 or 
```bash
sudo apt install -y kubelet=1.26.5-00 kubeadm=1.26.5-00 kubectl=1.26.5-00
```

- Install Kubernetes components 1.29
```bash
sudo apt-get install -y kubelet=1.29.1-1.1 kubeadm=1.29.1-1.1 kubectl=1.29.1-1.1
```

- Pin the versions
```bash
sudo apt-mark hold kubelet kubeadm kubectl
```

- Install Docker
```bash
sudo apt install docker.io -y
```

- Create a default configuration file for containerd and save it as config.toml
- Configure containerd
```bash
sudo mkdir /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd.service
```

- Restart and enable kubelet
```bash
sudo systemctl restart kubelet.service
sudo systemctl enable kubelet.service
```

------------------------------------------------------------------------------------------------------------

### Do the following for master node and all workernodes
