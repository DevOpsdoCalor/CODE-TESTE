#!/bin/bash

chosen_env=$1
if [[ "$1" = "" || ( "$2" != "" && "$2" != "ui" ) ]]; then
    vals=$(ls values | xargs -L1 -i{} basename {} .yaml 2>/dev/null)
    echo "Usage: apply.sh <$(echo $vals | sed -e "s, ,/,g")> <ui>"
    exit 0
elif [ ! -f values/$chosen_env.yaml ]; then
    echo "Cannot find values/$chosen_env.yaml"
    exit 1
fi

ctx=$(kubectx -c)
echo "This will customize and apply the deployment corresponding to $ctx @ $chosen_env."
echo -n "Do you want to continue (y/n) "
read -n 1 ans
echo
if [ $ans != "y" -a "$ans" != "Y" ]; then
    echo "Operation aborted by user"
    exit 0
fi

# Ensure WSL config can be deployed only on docker-desktop context
if [ "$chosen_env" = "local" -a "$ctx" != "docker-desktop" -a "$ctx" != "microk8s" ]; then
    echo "CRITICAL: Cannot deploy local configs to $ctx"
    exit 0
fi

#Uncomment and set KUBECONFIG env variable, if not set already. Default is '~/.kube/config'
#export KUBECONFIG=/path/to/.kube/config

# Render helm templates
if [ "$ctx" = "microk8s" ]; then
    m=microk8s
fi
$m helm template psp-helm . --output-dir out -f values/$1.yaml

ns=$(kubens -c)

if [ "$chosen_env" != "local" ]; then
    echo -n "Is this a GCP deployment with pods that need GPU access (y/n)? "
    read -n 1 ans
    echo
    if [ $ans == "y" -o "$ans" == "Y" ]; then
        echo "Deploying with GCP GPU support"
        kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml
    fi
fi

echo -n "Do you want to deploy Kafka (y/n)? "
read -n 1 ans
echo
if [ $ans == "y" -o "$ans" == "Y" ]; then
    echo "Deploying Kafka"
    kubectl apply -f out/psp-helm/templates/kafka.yaml
fi

# Create ns
kubectl apply -f out/psp-helm/templates/psp-ns.yaml
kubectl config set-context --current --namespace=psp

echo -n "Do you want to deploy the secret for the DockerHub credentials from the 'templates/regcred.yaml' file (y/n)? "
read -n 1 ans
echo
if [ $ans == "y" -o "$ans" == "Y" ]; then
    echo "Deploying secret"
    kubectl apply -f out/psp-helm/templates/regcred.yaml
fi

if [ "$chosen_env" = "local" ]; then
    echo "Deploying persistent volume claim 'psp-pv'"
    kubectl apply -f out/psp-helm/templates/psp-pv.yaml
fi

# Deploy mandatory config map volumes
# Deploy SSL certs
kubectl apply -f out/psp-helm/templates/psp-sslcerts-cm.yaml
# Deploy Google storage credentials
kubectl apply -f out/psp-helm/templates/psp-gs-cm.yaml
# Deploy worker with configmap
kubectl apply -f out/psp-helm/templates/psp-worker-deployments-cm.yaml

# Deploy orchestrator
kubectl apply -f out/psp-helm/templates/psp-orchestrator.yaml

kubectl config set-context --current --namespace=default
:<<comm
# Create separate namespace for monitoring
kubectl create ns monitoring
# Add Loki's chart repo
helm repo add grafana https://grafana.github.io/helm-charts
# Add Prometheus's chart repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# Update the chart repo
helm repo update
# Deploy Loki
helm upgrade --install loki --namespace monitoring grafana/loki-stack
# Deploy Prometheus
helm upgrade --install prometheus --version 40.3.0 --namespace monitoring prometheus-community/kube-prometheus-stack
# Deploy Grafana
kubectl apply -f out/psp-helm/templates/grafana.yaml
comm

if [[ "$2" != "ui" ]]; then
    kubectl config set-context --current --namespace=$ns
    exit 0
fi

echo '$KUBECONFIG : '$KUBECONFIG
echo 'Installing MongoDB :'
helm upgrade --install mongodb mongodb -f mongodb/values-$1.yaml
echo 'Installing Image gallery service (IGS) :'
helm upgrade --install igs image-gallery-service -f image-gallery-service/values-$1.yaml
echo 'Installing PSP UI :'
helm upgrade --install psp-ui psp-ui -f psp-ui/values-$1.yaml
kubectl config set-context --current --namespace=$ns
