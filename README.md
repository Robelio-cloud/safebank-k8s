# SafeBank Digital - Kubernetes Infrastructure

## Sobre o Projeto

Este repositório contém a implementação da infraestrutura Kubernetes para a **SafeBank Digital**, uma empresa fictícia que está migrando seus sistemas legados para containers. O objetivo é demonstrar a capacidade de implantar e expor aplicações web em um ambiente Kubernetes real na AWS.

## Arquitetura da Solução

### Componentes Implementados

- **Pod**: Container individual rodando aplicação web NGINX
- **Deployment**: Gerenciamento de múltiplas réplicas da aplicação 
- **Service**: Exposição da aplicação via AWS Load Balancer
- **ConfigMap**: Conteúdo HTML customizado da aplicação

### Infraestrutura

- **Cloud Provider**: AWS EC2
- **Kubernetes**: v1.31.12
- **Container Runtime**: containerd
- **CNI**: Flannel
- **Cluster Type**: Single-node (control-plane sem taint)

## Estratégia de Exposição: NodePort

### Estratégia Escolhida: NodePort (porta 30080)

### Justificativa da Escolha

#### Processo de Decisão:

* **Tentativa inicial**: O objetivo era utilizar um `Service` do tipo `LoadBalancer` para simular um ambiente de produção real.
* **Limitação identificada**: A criação automática de um AWS Elastic Load Balancer (ELB) por um `Service` do tipo `LoadBalancer` não funciona em uma instalação Kubernetes "standalone" em uma única instância EC2. Essa funcionalidade é nativa de serviços gerenciados como o Amazon EKS.
* **Solução pragmática**: Para garantir a acessibilidade externa do projeto, a solução escolhida foi usar um `Service` do tipo `NodePort`, que expõe a aplicação em uma porta fixa (30080) em cada nó. Em seguida, um **Security Group da AWS** foi configurado para permitir o tráfego externo para essa porta.
* **Resultado**: A aplicação ficou acessível externamente, mantendo a escalabilidade e a funcionalidade esperadas.
* **Próximos passos**: Em um ambiente de produção real, como o **Amazon EKS**, a estratégia ideal seria usar novamente um `Service` do tipo `LoadBalancer` em conjunto com o **AWS Load Balancer Controller**, que gerencia de forma nativa a criação de ELBs na infraestrutura AWS.

#### Vantagens do NodePort para este cenário:

1. **Funcionalidade Imediata**
   - Exposição direta da aplicação sem dependências externas
   - Controle total sobre a porta de exposição (30080)
   - Compatível com qualquer infraestrutura Kubernetes

2. **Integração com AWS**
   - Security Groups da AWS para controle de acesso
   - Escalabilidade horizontal dos pods mantida
   - Monitoramento via CloudWatch possível

3. **Simplicidade Operacional**
   - Configuração direta e transparente
   - Troubleshooting simplificado
   - Adequado para ambientes de desenvolvimento e validação

## Estrutura dos Arquivos

```
├── deploy.sh          # Script de automatização que dispara e orquestra os comandos do Kubernetes 
├── deployment.yaml    # Deployment com 3 réplicas + ConfigMap
├── service.yaml      # Service LoadBalancer com configurações AWS
├── pod.yaml          # Pod standalone para testes individuais
└── README.md         # Documentação do projeto
```

## Como Implantar

### Pré-requisitos

- Cluster Kubernetes funcionando na AWS
- kubectl configurado
- Permissões AWS para criar Load Balancers

### Passos de Implantação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/Robelio-cloud/safebank-k8s.git
   cd safebank-k8s
   ```

2. **Implante o ConfigMap e Deployment**
   ```bash
   kubectl apply -f deployment.yaml
   ```

3. **Crie o Service LoadBalancer**
   ```bash
   kubectl apply -f service.yaml
   ```

4. **Verifique o status da implantação**
   ```bash
   kubectl get deployments
   kubectl get pods -l app=safebank-web
   kubectl get service safebank-web-service
   ```

5. **Obtenha o endpoint público**
   ```bash
   kubectl get service safebank-web-service -o wide
   ```
### Implantação Automatizada (./deploy.sh)

![image](/assets/K8S-12.png)
![image](/assets/K8S-12.1.png)

### Implantação Alternativa (Pod Standalone)

Para testes ou desenvolvimento:
```bash
kubectl apply -f pod.yaml
```

## Validação da Solução

### Comandos de Verificação

```bash
# Verificar pods em execução
kubectl get pods -l app=safebank-web -o wide

# Verificar service e endpoint externo
kubectl get svc safebank-web-service

# Verificar logs da aplicação
kubectl logs -l app=safebank-web --tail=10

# Testar acesso interno
kubectl port-forward service/safebank-web-service 8080:80
```

### Testes de Escalabilidade

```bash
# Escalar para 5 réplicas
kubectl scale deployment safebank-web --replicas=5

# Verificar distribuição
kubectl get pods -l app=safebank-web -o wide

# Retornar para 3 réplicas
kubectl scale deployment safebank-web --replicas=3
```

## Monitoramento e Troubleshooting

### Logs e Debug

```bash
# Logs detalhados do deployment
kubectl describe deployment safebank-web

# Logs de um pod específico
kubectl logs <pod-name>

# Executar shell dentro do pod
kubectl exec -it <pod-name> -- /bin/sh

```
### Imagens de comandos de verificação, escalabilidade e monitoramento

![image](/assets/k8s-01.png)

![image](/assets/K8S-02.png)

![image](/assets/K8S-03.png)

![image](/assets/K8S-04.png)

![image](/assets/K8S-05.png)

![image](/assets/K8S-05.png)

![image](/assets/K8S-07.png)

![image](/assets/K8S-08.png)

![image](/assets/K8S-09.png)

![image](/assets/K8S-10.png)

![image](/assets/K8S-11.png)

![image](/assets/K8S-13.png)

![image](/assets/K8S-14-descr.png)

![image](/assets/K8S-15-logs.png)


### Health Checks

A aplicação inclui:
- **Liveness Probe**: Verifica se o container está saudável
- **Readiness Probe**: Verifica se está pronto para receber tráfego
- **Resource Limits**: Controle de CPU e memória

## Recursos da Aplicação

### Página Web

A aplicação web inclui:
- Interface responsiva com design moderno
- Informações sobre a infraestrutura Kubernetes
- Status de health da aplicação
- Identificação do pod/replica em execução

![image](assets/k8s-03.1.png)

### Características Técnicas

- **Image**: nginx:1.25-alpine (segura e otimizada)
- **Resources**: CPU 50m-100m, Memory 64Mi-128Mi
- **Port**: 80 (HTTP)
- **Volume**: ConfigMap montado para conteúdo HTML

## Conclusão

Esta implementação demonstra uma abordagem profissional para implantação de aplicações em Kubernetes, utilizando best practices como:

- Separação de concerns (Pod, Deployment, Service, ConfigMap)
- Health checks e resource management
- Estratégia de exposição adaptativa conforme limitações de infraestrutura
- Documentação completa para o time de desenvolvimento

A solução com NodePort, embora diferente do planejado inicialmente, demonstra flexibilidade técnica e capacidade de adaptação às limitações reais da infraestrutura. O resultado final proporciona uma validação efetiva da infraestrutura Kubernetes, permitindo que a equipe de desenvolvimento da SafeBank Digital teste e valide suas aplicações em um ambiente containerizado funcional.

A experiência de migrar de LoadBalancer para NodePort ilustra decisões técnicas do mundo real, onde soluções precisam ser adaptadas conforme o contexto e recursos disponíveis.

## Próximos Passos

- Implementar HTTPS/SSL no Load Balancer
- Adicionar métricas com Prometheus
- Configurar CI/CD pipeline
- Implementar logging centralizado
- Adicionar testes automatizados