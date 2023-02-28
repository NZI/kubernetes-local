#!/bin/bash

echo "wip"
exit

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

helm install metallb metallb/metallb -n metallb -f metallb.yaml