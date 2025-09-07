# Урок 8-9: Повний CI/CD з Jenkins + Terraform + ECR + Helm + Argo CD

## Опис проєкту

Цей проєкт демонструє реалізацію повного CI/CD pipeline'у, який об'єднує Jenkins, Terraform, Amazon ECR, Helm та Argo CD для автоматичного розгортання Django-застосунку без ручного втручання.

## Архітектура CI/CD

```
[Django App Code] 
    ↓ (git push)
[Jenkins Pipeline]
    ↓ (build & push)
[Amazon ECR]
    ↓ (update values.yaml)
[Git Repository]
    ↓ (git push)
[Argo CD]
    ↓ (sync)
[EKS Cluster] → [Django App]
```

## Компоненти

### Infrastructure (Terraform):
- **EKS Cluster**: Kubernetes кластер версії 1.28 з 2 worker nodes
- **VPC**: Virtual Private Cloud з публічними та приватними підмережами
- **ECR**: Elastic Container Registry для зберігання Docker образів
- **Jenkins**: CI/CD сервер, встановлений через Helm
- **Argo CD**: GitOps deployment tool, встановлений через Helm

### CI/CD Pipeline:
1. **Jenkins Pipeline**: Збирає Docker образ, пушить до ECR, оновлює Helm chart
2. **Argo CD**: Автоматично синхронізує зміни з Git репозиторію до Kubernetes

## Встановлення та налаштування

### Попередні вимоги

1. AWS CLI налаштовано з правильними credentials
2. Terraform встановлено (версія >= 1.0)
3. kubectl встановлено
4. Helm встановлено (версія >= 3.0)
5. Git repository для Helm charts

### Кроки розгортання

#### 1. Ініціалізація інфраструктури

```bash
cd lesson-8-9
terraform init
terraform plan
terraform apply
```

#### 2. Налаштування kubectl

```bash
aws eks update-kubeconfig --region eu-west-1 --name lesson-8-9-eks-cluster
kubectl get nodes
```

#### 3. Створення додаткових ConfigMaps

```bash
kubectl apply -f docker-config.yaml
```

#### 4. Налаштування Jenkins

1. Отримати URL та credentials:
```bash
terraform output jenkins_url
terraform output jenkins_admin_password
```

2. Увійти до Jenkins UI та налаштувати:
    - AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
    - GitHub token для доступу до helm charts repository
    - Pipeline job з Jenkinsfile з основного репозиторію

#### 5. Налаштування Argo CD

1. Отримати URL та credentials:
```bash
terraform output argocd_url
terraform output argocd_admin_password
```

2. Увійти до Argo CD UI:
    - Username: `admin`
    - Password: з terraform output

3. Налаштувати Git repository для helm charts

## Workflow CI/CD

### 1. Developer Push
```bash
# Developer commits changes to Django app
git add .
git commit -m "Add new feature"
git push origin main
```

### 2. Jenkins Pipeline (автоматично)
1. **Checkout**: Клонує код з Git
2. **Build**: Збирає Docker образ з унікальним тегом (`build-number-git-hash`)
3. **Push**: Завантажує образ до ECR
4. **Update**: Оновлює `values.yaml` у helm charts repository з новим тегом
5. **Commit**: Пушить зміни в helm repository

### 3. Argo CD Sync (автоматично)
1. **Detect**: Виявляє зміни в helm charts repository
2. **Sync**: Синхронізує нову версію застосунку в Kubernetes
3. **Deploy**: Розгортає оновлений застосунок

## Моніторинг та управління

### Jenkins
```bash
# Перевірка Jenkins pods
kubectl get pods -n jenkins

# Перегляд Jenkins logs
kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller
```

### Argo CD
```bash
# Перевірка Argo CD pods
kubectl get pods -n argocd

# Перевірка стану applications
kubectl get applications -n argocd
```

### Django App
```bash
# Перевірка deployment
kubectl get deployment django-app

# Перевірка pods
kubectl get pods -l app.kubernetes.io/name=django-app

# Перевірка service
kubectl get service django-app
```

## Terraform Modules

### Jenkins Module (`./modules/jenkins/`)
- **jenkins.tf**: Helm release та Kubernetes ресурси
- **providers.tf**: Kubernetes та Helm провайдери
- **variables.tf**: Змінні для налаштування
- **values.yaml**: Конфігурація Jenkins
- **outputs.tf**: URL, credentials

### Argo CD Module (`./modules/argo_cd/`)
- **argo_cd.tf**: Helm release та Application ресурси
- **providers.tf**: Kubernetes та Helm провайдери
- **variables.tf**: Змінні для налаштування
- **values.yaml**: Конфігурація Argo CD
- **outputs.tf**: URL, credentials
- **charts/**: Helm chart для створення Argo CD Applications

## Налаштування Jenkins Pipeline

### Необхідні Jenkins Credentials:
1. **aws-ecr-creds**: AWS Access Key та Secret Key для ECR
2. **github-token**: GitHub Personal Access Token для helm charts repository

### Environment Variables:
- `ECR_REPOSITORY`: URL ECR репозиторію
- `GIT_REPO`: URL helm charts Git репозиторію
- `DOCKERFILE_PATH`: Шлях до Dockerfile (./lesson-4)
- `CHART_PATH`: Шлях до Helm chart в helm repository

## Налаштування Argo CD

### Git Repository Configuration:
1. URL: `https://github.com/your-username/helm-charts`
2. Path: `charts/django-app`
3. Target Revision: `main`

### Sync Policy:
- **Automated**: `prune: true, selfHeal: true`
- **Sync Options**: `CreateNamespace=true`

## Вирішення проблем

### Jenkins не може push до ECR:
```bash
# Перевірити AWS credentials
kubectl get secret aws-credentials -n jenkins -o yaml

# Оновити credentials
kubectl create secret generic aws-credentials -n jenkins \
  --from-literal=AWS_ACCESS_KEY_ID=your-key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your-secret \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Argo CD не синхронізує:
```bash
# Перевірити Argo CD application
kubectl describe application django-app -n argocd

# Примусова синхронізація
kubectl patch application django-app -n argocd -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}' --type=merge
```

### Helm chart не оновлюється:
1. Перевірити, чи правильний Git repository URL в Argo CD
2. Перевірити permissions для GitHub token в Jenkins
3. Перевірити синтаксис values.yaml після оновлення

## Результати розгортання

### Створені ресурси AWS:
- ✅ EKS Cluster: `lesson-8-9-eks-cluster`
- ✅ ECR Repository: `lesson-8-9-ecr`
- ✅ VPC з публічними та приватними підмережами
- ✅ S3 bucket для Terraform state
- ✅ DynamoDB таблиця для блокувань

### Kubernetes ресурси:
- ✅ Jenkins: Namespace `jenkins` з LoadBalancer service
- ✅ Argo CD: Namespace `argocd` з LoadBalancer service
- ✅ Django App: Deployment з HPA у namespace `default`

### CI/CD Workflow:
- ✅ Автоматична збірка Docker образу
- ✅ Публікація в ECR з унікальними тегами
- ✅ Автоматичне оновлення Helm chart
- ✅ GitOps розгортання через Argo CD

## Очищення ресурсів

```bash
# Видалити Helm releases
helm uninstall django-app -n default
helm uninstall jenkins -n jenkins  
helm uninstall argocd -n argocd

# Видалити Terraform ресурси
terraform destroy
```

## Структура проєкту

```
lesson-8-9/
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальне виведення ресурсів
├── README.md                # Документація проєкту
│
├── modules/
│   ├── s3-backend/         # S3 та DynamoDB для Terraform state
│   ├── vpc/                # Virtual Private Cloud
│   ├── ecr/                # Elastic Container Registry
│   ├── eks/                # EKS кластер та node groups
│   ├── jenkins/            # Jenkins через Helm
│   │   ├── jenkins.tf      # Helm release та K8s ресурси
│   │   ├── providers.tf    # Kubernetes + Helm провайдери
│   │   ├── variables.tf    # Змінні модуля
│   │   ├── values.yaml     # Jenkins конфігурація
│   │   └── outputs.tf      # URL, credentials
│   └── argo_cd/            # Argo CD через Helm
│       ├── argo_cd.tf      # Helm release та Applications
│       ├── providers.tf    # Kubernetes + Helm провайдери
│       ├── variables.tf    # Змінні модуля
│       ├── values.yaml     # Argo CD конфігурація
│       ├── outputs.tf      # URL, credentials
│       └── charts/         # Helm chart для Applications
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               └── application.yaml
│ 
└── django-chart/                  # Helm чарти для деплою
        ├── templates/       # Kubernetes шаблони
        │   ├── deployment.yaml   # Deployment з автомасштабуванням
        │   ├── service.yaml      # LoadBalancer сервіс
        │   ├── configmap.yaml    # Змінні середовища
        │   └── hpa.yaml          # Horizontal Pod Autoscaler
        ├── Chart.yaml       # Метадані чарта
        └── values.yaml      # Конфігурація за замовчуванням
```
