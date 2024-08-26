## Setting up Kubernetes-cluster
### 1) Do the following for master node and all workernodes

- Update and Upgrade
```
sudo apt update -y
sudo apt upgrade -y
sudo apt install qemu-guest-agent -y
```

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

Configure apt for Kubernetes 1.28
```bash
sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
```

- Install Kubernetes components 1.28
```bash
sudo apt install -y kubelet=1.28.2-1.1 kubeadm=1.28.2-1.1 kubectl=1.28.2-1.1
sudo apt-mark hold kubelet kubeadm kubectl
```

- Configure apt for Kubernetes 1.29
```bash
sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
```

- Install Kubernetes components 1.29
```bash
sudo apt-get install -y kubelet=1.29.1-1.1 kubeadm=1.29.1-1.1 kubectl=1.29.1-1.1
sudo apt-mark hold kubelet kubeadm kubectl
```

- Pin the versions
```bash
sudo apt-mark hold kubelet kubeadm kubectl
```

- Install Docker
```bash
sudo apt install docker.io -y
```

- Install nfs-common: Only needed for flask-cmdhelper deployment app.
```bash
sudo apt-get install nfs-common
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

### 2) Do the following for master node
- Initialize the Kubernetes cluster on the master node
- When initializing Kubeadm on the master node, you will receive a token that you can use to add worker nodes
```bash
sudo kubeadm config images pull

# The --pod-network-cidr flag is setting the IP address range for the pod network
sudo kubeadm init --pod-network-cidr=10.10.0.0/16
```

- Create the .kube directory in your home folder and copy the cluster's admin configuration to your personal .kube directory.
- Next, change the ownership of the copied configuration file to give the user the permission to use the configuration file to interact with the cluster.
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

- Configure kubectl and Calico
```bash
# deploy the calico operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# download the custom resource file for calico
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O
```

- Use the sed command to change the default CIDR value in the Calico custom resources to match the CIDR you used in the kubeadm init command
```bash
sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 10.10.0.0\/16/g' custom-resources.yaml
```

- Tell kubectl to create the resources defined in the custom-resources.yaml file
```bash
kubectl create -f custom-resources.yaml
```

- At this point, you can go into the worker nodes and use kubeadm join command to join the master node
- You can use the following to generate the original command on your master node
```bash
kubeadm token create --print-join-command
```

