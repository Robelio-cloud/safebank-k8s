#!/bin/bash

# SafeBank Digital - Script de Deploy Automatizado (NodePort)
# Autor: SafeBank DevOps Team
# Versão: 1.1 (Adaptado para NodePort)

set -e  # Parar execução em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Verificar se kubectl está disponível
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl não encontrado. Instale kubectl primeiro."
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        error "Não foi possível conectar ao cluster Kubernetes."
        exit 1
    fi

    success "Conexão com cluster Kubernetes OK"
}

# Verificar se estamos na AWS
check_aws_environment() {
    log "Verificando ambiente AWS..."

    # Verifica se conseguimos acessar metadata da EC2
    if curl -s --max-time 5 http://169.254.169.254/latest/meta-data/instance-id > /dev/null 2>&1; then
        success "Ambiente AWS detectado"
        INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
        REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
        log "Instance ID: $INSTANCE_ID"
        log "Region: $REGION"
    else
        warn "Não foi possível detectar ambiente AWS, continuando..."
    fi
}

# Deploy da aplicação
deploy_application() {
    log "Iniciando deploy da aplicação SafeBank..."

    # Aplicar deployment (inclui ConfigMap)
    log "Aplicando Deployment e ConfigMap..."
    kubectl apply -f deployment.yaml

    # Aguardar deployment estar pronto
    log "Aguardando deployment ficar pronto..."
    kubectl rollout status deployment/safebank-web --timeout=300s

    success "Deployment aplicado com sucesso"
}

# Deploy do service
deploy_service() {
    log "Criando Service NodePort..."
    kubectl apply -f service.yaml

    success "Service criado com sucesso"
}

# Verificar status do deployment
check_deployment_status() {
    log "Verificando status do deployment..."

    # Verificar pods
    echo -e "\n${YELLOW}=== PODS ===${NC}"
    kubectl get pods -l app=safebank-web -o wide

    # Verificar service
    echo -e "\n${YELLOW}=== SERVICE ===${NC}"
    kubectl get service safebank-web-service

    # Verificar endpoints
    echo -e "\n${YELLOW}=== ENDPOINTS ===${NC}"
    kubectl get endpoints safebank-web-service
}

# Testar aplicação
test_application() {
    log "Testando aplicação..."

    # Teste interno via port-forward
    kubectl port-forward service/safebank-web-service 8080:80 &
    PF_PID=$!

    sleep 5

    if curl -s --max-time 10 http://localhost:8080 | grep -q "SafeBank Digital"; then
        success "Aplicação respondendo corretamente (teste local)"
    else
        warn "Aplicação pode não estar respondendo corretamente"
    fi

    # Parar port-forward
    kill $PF_PID 2>/dev/null || true

    # Teste externo se a EC2 tiver IP público
    local EXTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    local NODE_PORT=30080

    if [ -n "$EXTERNAL_IP" ]; then
        log "Testando acesso externo via NodePort..."
        if curl -s --max-time 15 "http://${EXTERNAL_IP}:${NODE_PORT}" | grep -q "SafeBank Digital"; then
            success "Aplicação acessível externamente via NodePort!"
        else
            warn "Aplicação pode não estar acessível externamente ainda."
            echo "Verifique o Security Group e o IP público da sua EC2."
        fi
    fi
}

# Exibir informações finais
show_final_info() {
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  SAFEBANK DIGITAL - DEPLOY COMPLETO  ${NC}"
    echo -e "${YELLOW}========================================${NC}\n"

    echo -e "${BLUE}Comandos úteis:${NC}"
    echo "  kubectl get pods -l app=safebank-web"
    echo "  kubectl get service safebank-web-service"
    echo "  kubectl logs -l app=safebank-web --tail=20"
    echo "  kubectl scale deployment safebank-web --replicas=5"

    echo -e "\n${BLUE}Para testar localmente:${NC}"
    echo "  kubectl port-forward service/safebank-web-service 8080:80"
    echo "  curl http://localhost:8080"

    local EXTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    local NODE_PORT=30080

    if [ -n "$EXTERNAL_IP" ]; then
        echo -e "\n${GREEN}🎉 Aplicação disponível em: http://${EXTERNAL_IP}:${NODE_PORT}${NC}"
        echo -e "${YELLOW}Lembre-se de que o Security Group da sua EC2 deve permitir acesso à porta ${NODE_PORT}.${NC}"
    else
        echo -e "\n${YELLOW}Não foi possível obter o IP público da instância. Execute:${NC}"
        echo "  kubectl get service safebank-web-service"
    fi

    echo -e "\n${BLUE}Repositório GitHub:${NC} https://github.com/Robelio-cloud/safebank-k8s\n"
}

# Função principal
main() {
    log "Iniciando deploy da SafeBank Digital no Kubernetes"

    check_kubectl
    check_aws_environment
    deploy_application
    deploy_service
    check_deployment_status
    test_application
    show_final_info
}

# Verificar se os arquivos YAML existem
if [ ! -f "deployment.yaml" ] || [ ! -f "service.yaml" ]; then
    error "Arquivos deployment.yaml ou service.yaml não encontrados!"
    echo "Certifique-se de estar no diretório correto do projeto."
    exit 1
fi

# Executar função principal
main