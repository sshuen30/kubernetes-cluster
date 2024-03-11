## Setting up Kubernetes-cluster
### Do the following for master node and all workernodes

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
```
