# SafeBank Digital - Infraestrutura Kubernetes

---

### Sobre o Projeto

Este repositório contém a implementação da infraestrutura **Kubernetes** para a **SafeBank Digital**, uma empresa fictícia que está migrando seus sistemas legados para containers. O objetivo é demonstrar a capacidade de implantar e expor aplicações web em um ambiente Kubernetes real na AWS.

### Arquitetura da Solução

#### Componentes Implementados

* **Pod**: Container individual rodando aplicação web **NGINX**.
* **Deployment**: Gerenciamento de múltiplas réplicas da aplicação.
* **Service**: Exposição da aplicação via **AWS Load Balancer**.
* **ConfigMap**: Conteúdo HTML customizado da aplicação.

#### Infraestrutura

* **Cloud Provider**: AWS EC2
* **Kubernetes**: v1.31.12
* **Container Runtime**: containerd
* **CNI**: Flannel
* **Cluster Type**: Single-node (control-plane sem taint)
* **Estratégia de Exposição**: LoadBalancer

---

### Escolha Técnica

Optei por utilizar um Service do tipo `LoadBalancer` com **AWS Network Load Balancer (NLB)**.

#### Justificativa da Escolha

**Vantagens do LoadBalancer:**

* **Proximidade com Produção Real**: Em ambientes de produção, LoadBalancers são o padrão para exposição de aplicações, abstraindo a complexidade de rede dos desenvolvedores.
* **Integração nativa com a infraestrutura AWS**: Se integra perfeitamente com os recursos da AWS.
* **Escalabilidade Automática**: O NLB distribui automaticamente o tráfego entre as réplicas, com suporte nativo a `health checks` e capacidade de lidar com alto volume de requisições.
* **Segurança e Isolamento**: Não expõe portas específicas dos nós (como `NodePort` faria) e permite controle de acesso via Security Groups da AWS.

**Comparação com Outras Opções:**

| Opção | Uso | Por que foi preterida? |
| :--- | :--- | :--- |
| **Port-forward** | Desenvolvimento local | Não adequado para validação de infraestrutura |
| **NodePort** | Exposição simples em portas dos nós | Menos elegante e mais limitado para ambientes de produção |
| **LoadBalancer** | Solução de nível empresarial | Ideal para uma validação realista |

---

### Estrutura dos Arquivos

├── deployment.yaml    # Deployment com 3 réplicas + ConfigMap

├── service.yaml      # Service LoadBalancer com configurações AWS

├── pod.yaml          # Pod standalone para testes individuais

└── README.md         # Documentação do projeto



---

### Como Implantar

#### Pré-requisitos

* Cluster Kubernetes funcionando na AWS.
* `kubectl` configurado.
* Permissões AWS para criar Load Balancers.

#### Passos de Implantação

1.  Clone o repositório:
    ```bash
    git clone [https://github.com/Robelio-cloud/safebank-k8s.git](https://github.com/Robelio-cloud/safebank-k8s.git)
    cd safebank-k8s
    ```
2.  Implante o `ConfigMap` e `Deployment`:
    ```bash
    kubectl apply -f deployment.yaml
    ```
3.  Crie o Service `LoadBalancer`:
    ```bash
    kubectl apply -f service.yaml
    ```
4.  Verifique o status da implantação:
    ```bash
    kubectl get deployments
    kubectl get pods -l app=safebank-web
    kubectl get service safebank-web-service
    ```
5.  Obtenha o endpoint público:
    ```bash
    kubectl get service safebank-web-service -o wide
    ```

#### Implantação Alternativa (Pod Standalone)

Para testes ou desenvolvimento:

```bash
kubectl apply -f pod.yaml
Validação da Solução
Comandos de Verificação
Bash

# Verificar pods em execução
kubectl get pods -l app=safebank-web -o wide

# Verificar service e endpoint externo
kubectl get svc safebank-web-service

# Verificar logs da aplicação
kubectl logs -l app=safebank-web --tail=10

# Testar acesso interno
kubectl port-forward service/safebank-web-service 8080:80
Testes de Escalabilidade
Bash

# Escalar para 5 réplicas
kubectl scale deployment safebank-web --replicas=5

# Verificar distribuição
kubectl get pods -l app=safebank-web -o wide

# Retornar para 3 réplicas
kubectl scale deployment safebank-web --replicas=3
Monitoramento e Troubleshooting
Logs e Debug
Bash

# Logs detalhados do deployment
kubectl describe deployment safebank-web

# Logs de um pod específico
kubectl logs <pod-name>

# Executar shell dentro do pod
kubectl exec -it <pod-name> -- /bin/sh

# Verificar eventos do cluster
kubectl get events --sort-by='.metadata.creationTimestamp'
Health Checks
A aplicação inclui:

Liveness Probe: Verifica se o container está saudável.

Readiness Probe: Verifica se está pronto para receber tráfego.

Resource Limits: Controle de CPU e memória.

Recursos da Aplicação
Página Web
A aplicação web inclui:

Interface responsiva com design moderno.

Informações sobre a infraestrutura Kubernetes.

Status de health da aplicação.

Identificação do pod/réplica em execução.

Características Técnicas
Image: nginx:1.25-alpine (segura e otimizada)

Resources: CPU 50m-100m, Memory 64Mi-128Mi

Port: 80 (HTTP)

Volume: ConfigMap montado para conteúdo HTML.

Conclusão
Esta implementação demonstra uma abordagem profissional para implantação de aplicações em Kubernetes, utilizando best practices como:

Separação de concerns (Pod, Deployment, Service, ConfigMap).

Health checks e resource management.

Estratégia de exposição adequada para produção.

Documentação completa para o time de desenvolvimento.

A escolha do LoadBalancer proporciona uma experiência próxima ao ambiente de produção, facilitando a validação da infraestrutura pela equipe de desenvolvimento da SafeBank Digital.

Próximos Passos
Implementar HTTPS/SSL no Load Balancer.

Adicionar métricas com Prometheus.

Configurar CI/CD pipeline.

Implementar logging centralizado.

Adicionar testes automatizados.

