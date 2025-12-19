# Kubernetes Instance with Terraform

Provisiona uma instância EC2 com Ubuntu, kubectl e minikube pré-instalados.

## Especificações

- **Instância**: t3.xlarge (4 vCPUs, 16GB RAM)
- **OS**: Ubuntu 22.04 LTS
- **IP**: Público
- **Ferramentas**: kubectl, minikube, Docker

## Portas Liberadas

- SSH (22)
- HTTP (80) 
- HTTPS (443)
- 8080
- Kube API (6443)

## Como Usar

1. **Configure as variáveis**:
   ```bash
   mkdir -p environment/dev
   cp terraform.tfvars.example environment/dev/terraform.tfvars
   ```
   
   Edite `environment/dev/terraform.tfvars`:
   ```
   key_pair_name = "seu-key-pair"
   aws_region = "us-east-1"
   ```

2. **Execute o Terraform**:
   ```bash
   terraform init
   terraform plan -var-file="environment/dev/terraform.tfvars"
   terraform apply -var-file="environment/dev/terraform.tfvars"
   ```

3. **Conecte via SSH**:
   ```bash
   ssh -i ~/.ssh/seu-key-pair.pem ubuntu@<IP_PUBLICO>
   ```

4. **Inicie o minikube**:
   ```bash
   ./start-minikube.sh
   ```

## Outputs

- `instance_public_ip`: IP público da instância
- `instance_public_dns`: DNS público da instância  
- `ssh_command`: Comando SSH para conexão

## Pré-requisitos

- Terraform instalado
- AWS CLI configurado
- Key pair criado na AWS

## Configuração do kubectl remoto

```bash
mkdir -p ~/.minikube
scp -i ~/key.pem ubuntu@98.93.89.190:~/.minikube/ca.crt ~/.minikube/remote-ca.crt
scp -i ~/key.pem ubuntu@98.93.89.190:~/.minikube/profiles/minikube/client.crt ~/.minikube/remote-client.crt
scp -i ~/key.pem ubuntu@98.93.89.190:~/.minikube/profiles/minikube/client.key ~/.minikube/remote-client.key

kubectl config set-cluster remote-minikube \
  --server=https://98.93.89.190:8443 \
  --certificate-authority=$HOME/.minikube/remote-ca.crt \
  --embed-certs=true

kubectl config set-credentials remote-minikube-user \
  --client-certificate=$HOME/.minikube/remote-client.crt \
  --client-key=$HOME/.minikube/remote-client.key \
  --embed-certs=true

kubectl config set-context remote-minikube \
  --cluster=remote-minikube \
  --user=remote-minikube-user

```

