#!/bin/bash

if [[ "$1" = "" ]]; then
    vals=$(ls values | xargs -L1 -i{} basename {} .yaml 2>/dev/null)
    echo "Usage: uninstall.sh <$(echo $vals | sed -e "s, ,/,g")>"
    exit 0
elif [ ! -f values/$1.yaml ]; then
    echo "Cannot find values/$1.yaml"
    exit 1
fi

echo "This will uninstall the deployments corresponding to $1."
echo -n "Do you want to continue (y/n) "
read -n 1 ans
echo
if [ $ans != "y" -a "$ans" != "Y" ]; then
    echo "Operation aborted by user"
    exit 0
fi
# Render helm templates
if [ "$ctx" = "microk8s" ]; then
    m=microk8s
fi
#Uncomment and set KUBECONFIG env variable, if not set already. Default is '~/.kube/config'
#export KUBECONFIG=/path/to/.kube/config
echo '$KUBECONFIG : '$KUBECONFIG

# Render helm templates
$m helm template psp-helm . --output-dir out -f values/$1.yaml

:<<comm
echo 'Removing Loki'
helm uninstall loki
echo 'Removing Grafana'
kubectl delete -f out/psp-helm/templates/grafana.yaml
comm

echo 'Removing kafka'
kubectl delete -f out/psp-helm/templates/kafka.yaml
echo 'Removing secret'
kubectl delete -f out/psp-helm/templates/regcred.yaml
echo 'Removing SSL certs'
kubectl delete -f out/psp-helm/templates/psp-sslcerts-cm.yaml
echo 'Removing namespace'
kubectl delete -f out/psp-helm/templates/psp-ns.yaml

if [ "$1" = "local" ]; then
    echo 'Removing persistant volume claim'
    kubectl delete -f out/psp-helm/templates/psp-pv.yaml
fi

echo 'Uninstalling MongoDB :'
helm uninstall mongodb
echo 'Uninstalling Image gallery service (IGS) :'
helm uninstall igs
echo 'Uninstalling PSP UI :'
helm uninstall psp-ui
