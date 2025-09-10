# SafeBank Digital - Kubernetes Infrastructure

![image](/assets/K8S-03.1.png)

## Sobre o Projeto

Este repositório contém a implementação da infraestrutura Kubernetes para a **SafeBank Digital**, uma empresa fictícia que está migrando seus sistemas legados para containers. O objetivo é demonstrar a capacidade de implantar e expor aplicações web em um ambiente Kubernetes real na AWS.

## Pré requisitos:

## Arquitetura da Solução

### Componentes Implementados

- **Pod**: Container individual rodando aplicação web NGINX
- **Deployment**: Gerenciamento de múltiplas réplicas da aplicação 
- **Service**: Exposição da aplicação via NodePort
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

#### Processo de Decisão frente ao Load Balancer e Port-Forward:

* **Limitação identificada**: A criação automática de um AWS Elastic Load Balancer (ELB) por um `Service` do tipo `LoadBalancer` não funciona em uma instalação Kubernetes "standalone" em uma única instância EC2. Essa funcionalidade é nativa de serviços gerenciados como o Amazon EKS.
* **Objetivo desejado**: O desejo do projeto era demonstrar uma aplicação acessível externamente de forma permanente, algo que o Port-Forward não poderia oferecer.
* **Solução pragmática**: Para garantir a acessibilidade externa do projeto, a solução escolhida foi usar um `Service` do tipo `NodePort`, que expõe a aplicação em uma porta fixa (30080) em cada nó. Em seguida, um **Security Group da AWS** foi configurado para permitir o tráfego externo para essa porta.
* **Resultado**: A aplicação ficou acessível externamente, mantendo a escalabilidade e a funcionalidade esperadas.


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
├── assets            # Pasta com prints de telas de comandos e Web-Site da aplicação 
├── deploy.sh          # Script de automatização que dispara e orquestra os comandos do Kubernetes 
├── deployment.yaml    # Deployment com 3 réplicas + ConfigMap
├── service.yaml      # Service LoadBalancer com configurações AWS
├── pod.yaml          # Pod standalone para testes individuais
└── README.md         # Documentação do projeto
```

## Como Implantar

### Pré-requisitos

Seguir o guia de instalação de Kubernetes em instância EC2 na AWS conforme link abaixo:

https://github.com/camanducci/k8s-lesson-2TCNPZ/blob/main/kubernetes/Install.md

Após a instalação teremos:

- Cluster Kubernetes funcionando na AWS
- kubectl configurado


### Passos de Implantação na EC2 já configurada na AWS.

![image](/assets/K8S-16-ec2.png)

### Configurar Security Group com regra de entrada Custom TCP com a porta 30080 para uso do NodePort:

![image](/assets/K8S-17-sg.png)

1. **Clone o repositório**

Acessar a EC2 Safebank Sever por ssh ou conectar pelo console da AWS.

   ```bash
   git clone https://github.com/Robelio-cloud/safebank-k8s.git
   cd safebank-k8s
   ```
### Implantação Automatizada (./deploy.sh)

Tornar o deploy.sh executável:

chmod +x deploy.sh

Executar:

./deploy.sh

![image](/assets/K8S-12.png)
![image](/assets/K8S-12.1.png)

### Etapas de Execução
Este script de shell automatiza o processo de implantação da aplicação "SafeBank Digital" em um cluster Kubernetes.

### Verificação de Ambiente:

Confere se o kubectl está instalado e conectado a um cluster Kubernetes.

Detecta se o script está sendo executado em um ambiente AWS.

### Implantação no Kubernetes:

Aplica o arquivo deployment.yaml para criar a aplicação e o ConfigMap.

Aplica o arquivo service.yaml para expor a aplicação por meio de um LoadBalancer.

### Validação e Testes:

Monitora o status do deployment para garantir que ele seja concluído.

Espera até que o NodePort tenha uma URL externa.

Realiza testes de conectividade para confirmar se a aplicação está respondendo corretamente.


### Implantação Manual

1. **Implante o ConfigMap e Deployment**
   ```bash
   kubectl apply -f deployment.yaml
   ```

2. **Crie o Service NodePort**
   ```bash
   kubectl apply -f service.yaml
   ```

3. **Verifique o status da implantação**
   ```bash
   kubectl get deployments
   kubectl get pods -l app=safebank-web
   kubectl get service safebank-web-service
   ```

4. **Obtenha o endpoint público**
   ```bash
   kubectl get service safebank-web-service -o wide
   ```

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
### Imagens de comandos de verificação, escalabilidade e monitoramento da aplicação:

![image](/assets/K8S-01.png)

![image](/assets/K8S-02.png)

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


## Recursos da Aplicação

### Página Web

### http://< PUBLIC_IP >:30080/

Verficar o IP público da instância EC2 para colocar no link.

A aplicação web inclui:
- Interface responsiva com design moderno
- Informações sobre a infraestrutura Kubernetes
- Status de health da aplicação
- Identificação do pod/replica em execução

![image](/assets/K8S-03.1.png)

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

A solução com NodePort, demonstra flexibilidade técnica e capacidade de adaptação às limitações reais da infraestrutura. O resultado final proporciona uma validação efetiva da infraestrutura Kubernetes, permitindo que a equipe de desenvolvimento da SafeBank Digital teste e valide suas aplicações em um ambiente containerizado funcional.
