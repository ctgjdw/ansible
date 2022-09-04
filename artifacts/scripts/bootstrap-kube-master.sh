#!/bin/bash
whoami
USERNAME=$1
KUBE_VER=$2
HOST_PRIVATE_IP=$(hostname -I | cut -d ' ' -f1)
printf "Installing K8=$KUBE_VER-00 on with IP: $HOST_PRIVATE_IP\n"

apt-get update && apt-get upgrade -y
apt-get install ca-certificates software-properties-common apt-transport-https curl gnupg lsb-release -y

swapoff -a && sed -i 's/\/swap/#\/swap/g' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

apt-get update
apt-get install -y containerd
apt-mark hold containerd

sudo mkdir -p /etc/containerd
cp /config/containerd-config.toml /etc/containerd/config.toml
sudo systemctl restart containerd

apt-get install -y kubelet=$KUBE_VER-00 kubeadm=$KUBE_VER-00 kubectl=$KUBE_VER-00
apt-mark hold kubelet kubeadm kubectl

echo "KUBELET_EXTRA_ARGS=--node-ip=$HOST_PRIVATE_IP" >>/etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address $HOST_PRIVATE_IP | tee /kubeadm.log

mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown "$(id -u):$(id -g)" /root/.kube/config

kubectl create -f /manifests/calico-operator.yml
kubectl create -f /manifests/calico-resource.yml

mkdir -p /home/$USERNAME/.kube
cp -i /etc/kubernetes/admin.conf /home/$USERNAME/.kube/config
chown -R "$USERNAME:$USERNAME" /home/$USERNAME/.kube/

# Due to config differences for Calico and kubeadm for the CNI plugins, copy all bins from old to new path
mkdir -p /usr/lib/cni
cp -r /opt/cni/bin/* /usr/lib/cni
