#!/bin/bash

# Atualizar sistema
apt-get update -y
apt-get upgrade -y

# Instalar dependências
apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release

# Instalar Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Adicionar usuário ubuntu ao grupo docker
usermod -aG docker ubuntu

# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Instalar minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube /usr/local/bin/

# Configurar minikube para usar docker driver
sudo -u ubuntu minikube config set driver docker

# Iniciar serviços
systemctl enable docker
systemctl start docker

sudo -u ubuntu minikube start --memory=8192 --cpus=4 --container-runtime=containerd --listen-address=0.0.0.0

# Criar script de inicialização do minikube para o usuário ubuntu
cat > /home/ubuntu/start-minikube.sh << 'EOF'
#!/bin/bash
minikube start --memory=8192 --cpus=4 --container-runtime=containerd
EOF

chmod +x /home/ubuntu/start-minikube.sh
chown ubuntu:ubuntu /home/ubuntu/start-minikube.sh

/home/ubuntu/start-minikube.sh

echo "Instalação concluída. Execute "

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh

sudo -u ubuntu cat > /home/ubuntu/values.yaml << 'EOF'
prometheus:
  enabled: true
  prometheusSpec:

    podMonitorSelector: {}
    podMonitorSelectorNilUsesHelmValues: false
    ruleSelector: {}
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelector: {}
    serviceMonitorSelectorNilUsesHelmValues: false
    scrapeConfigSelectorNilUsesHelmValues: false

kubeStateMetrics:
  enabled: true

alertmanager:
  enabled: false


prometheusOperator:
  enabled: true
  namespaces: ''
  denyNamespaces: ''
  prometheusInstanceNamespaces: ''
  alertmanagerInstanceNamespaces: ''
  thanosRulerInstanceNamespaces: ''

EOF

sudo -u ubuntu kubectl create ns prometheus
sudo -u ubuntu helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo -u ubuntu helm repo update
sudo -u ubuntu helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus -f /home/ubuntu/values.yaml
mkdir /root/.kube
cp /home/ubuntu/.kube/config /root/.kube/config

sudo -u ubuntu helm repo add istio https://istio-release.storage.googleapis.com/charts
sudo -u ubuntu helm repo update
sudo -u ubuntu helm install istio-base istio/base --namespace istio-system --create-namespace 
sudo -u ubuntu helm install istiod istio/istiod --namespace istio-system --set meshConfig.enableTracing="true" --set profile=ambient

sudo -u ubuntu cat > /home/ubuntu/istio-podmonitor.yaml << 'EOF'
apiVersion: v1
items:
- apiVersion: monitoring.coreos.com/v1
  kind: PodMonitor
  metadata:
      
    labels:
      release: prometheus
    name: istio-proxies-monitor
    namespace: prometheus
    
  spec:
    jobLabel: component
    namespaceSelector:
      any: true
    podMetricsEndpoints:
    - interval: 15s
      path: /stats/prometheus
      port: http-envoy-prom
    selector:
      matchLabels:
        security.istio.io/tlsMode: istio

EOF

sudo -u ubuntu kubectl apply -f /home/ubuntu/istio-podmonitor.yaml -n prometheus
#curl -L https://istio.io/downloadIstio | sh -
#cd istio-1.28.1
#export PATH=$PWD/bin:$PATH
#istioctl install --set profile=ambient --skip-confirmation
sudo -u ubuntu kubectl label namespace default istio-injection=enabled

sudo -u ubuntu helm install \
  --namespace istio-system \
  --set auth.strategy="anonymous" \
  --repo https://kiali.org/helm-charts \
  --set external_services.prometheus.url="http://prometheus-kube-prometheus-prometheus.prometheus.svc.cluster.local:9090" \
  kiali-server \
  kiali-server


