#!/bin/bash

# https://github.com/SKorolchuk/kubernetes-vagrant-cluster-experiments/blob/master/disable-swap.sh
# kubelet requires swap off
swapoff -a
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

dnf install -y yum-utils
modprobe overlay
modprobe br_netfilter


# Creating sysctl configuration and loading it

cat <<EOF | tee /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --load=/etc/sysctl.d/99-kubernetes.conf

# Installing CRI-O to use as runtime and configure few settings

dnf install -y jq
curl https://raw.githubusercontent.com/cri-o/cri-o/main/scripts/get | bash

cat <<EOF | tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

cat <<EOF | tee /etc/crio/crio.conf
[crio.runtime]
conmon_cgroup = "pod"
cgroup_manager = "systemd"
EOF

cat <<EOF | tee /etc/containers/registries.conf
unqualified-search-registries=["registry.fedoraproject.org", "docker.io"]
EOF

# Disable SELinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config


cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# https://stackoverflow.com/questions/59653331/kubernetes-centos-8-tc-command-missing-impact

dnf install -y iproute-tc

# Install kubelet, kubeadm and kubectl

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Disable firewalld (or you could just configure it)

systemctl disable --now firewalld

# Enable crio and kubelet
systemctl enable --now  kubelet crio

kubeadm reset -f

mkdir -p /home/vagrant/.kube
cp /vagrant/config/controller.config /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config
/vagrant/config/controller.join.sh