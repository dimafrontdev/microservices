# 🚀 Покрокова інструкція розгортання фінального проєкту

## 📋 Технічні вимоги
- **Інфраструктура**: AWS з використанням Terraform
- **Компоненти**: VPC, EKS, RDS, ECR, Jenkins, Argo CD, Prometheus, Grafana

## 🛠️ Етапи виконання

### 1. Підготовка середовища

```bash
# Перевірка необхідних інструментів
aws --version
terraform --version
kubectl version --client
helm version

# Налаштування AWS credentials
aws configure
# Введіть ваші AWS Access Key, Secret Key, Region: eu-west-1

# Клонування репозиторію (якщо потрібно)
cd /Users/vvpcode/dev/devops/my-microservice-project
```

### 2. Ініціалізація Terraform

```bash
# Ініціалізація Terraform
terraform init

# Валідація конфігурації
terraform validate

# Планування розгортання
terraform plan
```

**⚠️ Важливо**: Перед розгортанням перевірте:
- AWS credentials налаштовані правильно
- Регіон встановлений як `eu-west-1`
- Всі модулі знаходяться в папці `modules/`

### 3. Розгортання інфраструктури

```bash
# Розгортання всієї інфраструктури
terraform apply
# Введіть 'yes' для підтвердження

# ⏱️ Очікуваний час: 15-20 хвилин
```

**Порядок створення ресурсів:**
1. S3 bucket + DynamoDB (1-2 хв)
2. VPC + Subnets + NAT Gateway (3-4 хв)
3. ECR repository (30 сек)
4. EKS Cluster (8-10 хв)
5. RDS PostgreSQL (5-7 хв)
6. Jenkins Helm release (2-3 хв)
7. Argo CD Helm release (2-3 хв)
8. Prometheus + Grafana (3-4 хв)

### 4. Налаштування kubectl

```bash
# Оновлення kubeconfig для EKS
aws eks update-kubeconfig --region eu-west-1 --name final-project-eks-cluster

# Перевірка підключення
kubectl get nodes
kubectl get namespaces
```

### 5. Перевірка стану всіх компонентів

```bash
# Jenkins
kubectl get all -n jenkins
kubectl get pods -n jenkins

# Argo CD
kubectl get all -n argocd
kubectl get pods -n argocd

# Monitoring (Prometheus + Grafana)
kubectl get all -n monitoring
kubectl get pods -n monitoring

# Перевірка всіх PVC (Persistent Volume Claims)
kubectl get pvc --all-namespaces
```

### 6. 🌐 Доступ до сервісів через AWS URLs

#### Jenkins CI/CD 🔧
```bash
# Прямий доступ через AWS LoadBalancer
# URL: http://a016f3d06f8504012b4f4b9a13ebd33a-1981017016.eu-west-1.elb.amazonaws.com:8080
# Статус: ✅ HTTP 200 (Working)

# Альтернативно через kubectl:
kubectl get svc jenkins -n jenkins
```

#### Argo CD GitOps 🔄
```bash
# Прямий доступ через AWS LoadBalancer
# URL: https://a05fc9b53019d4e97b6470adb9ddee14-331120931.eu-west-1.elb.amazonaws.com
# Статус: ✅ HTTP 200 (Healthy + Synced)

#### Grafana Monitoring 📊
```bash
# Прямий доступ через AWS LoadBalancer
# URL: http://af6503eaf801a434b97d413d1df0241a-1422711606.eu-west-1.elb.amazonaws.com
# Статус: ✅ HTTP 302 (Ready)
```

#### Prometheus Metrics 📈
```bash
# Прямий доступ через AWS LoadBalancer
# URL: http://add504804b7d246a0bd5c576b6b7dd6c-1293644691.eu-west-1.elb.amazonaws.com:9090
# Статус: ✅ HTTP 302 (Ready)
```

#### Django Application 🐍
```bash
# URL: http://a40be67dd32e14e7bbd1588af4764378-416909794.eu-west-1.elb.amazonaws.com
# Статус: ✅ HTTP 200 (Running with 2 replicas + HPA)
```

### 7. 🐍 Розгортання Django додатку

```bash
# 1. Збирання Docker образу для правильної архітектури
cd Django/
docker build --platform linux/amd64 -t django-app:amd64 .

# 2. Tag для ECR (використовуємо фіксований URL)
ECR_URL="381492144666.dkr.ecr.eu-west-1.amazonaws.com/final-project-ecr"
docker tag django-app:amd64 $ECR_URL:amd64

# 3. Login до ECR
aws ecr get-login-password --region eu-west-1 

# 4. Push до ECR
docker push $ECR_URL:amd64

# 5. Розгортання через Helm (з правильною папкою)
cd ..
helm upgrade --install django-app ./charts/django-app \
    --set image.repository=$ECR_URL \
    --set image.tag=amd64 \
    --namespace default --create-namespace

# 6. Перевірка розгортання
kubectl get pods -l app.kubernetes.io/name=django-app
kubectl get svc django-app
```

### 8. 🔍 Перевірка доступності та метрик

```bash
# Статус Django застосунку
kubectl get pods -l app.kubernetes.io/name=django-app
kubectl get svc django-app
kubectl get hpa django-app

## 🔧 Корисні команди для налагодження

```bash
# Перевірка статусу всіх подів
kubectl get pods --all-namespaces

# Логи конкретного поду
kubectl logs <pod-name> -n <namespace>

# Опис ресурсу для налагодження
kubectl describe pod <pod-name> -n <namespace>

# Перевірка Events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Terraform outputs
terraform output

# Очистка ресурсів (якщо потрібно)
terraform destroy
```

## 📊 Фінальні результати розгортання ✅

**🏗️ Створена інфраструктура:**
- ✅ **EKS кластер**: `final-project-eks-cluster` з 2 worker nodes
- ✅ **RDS PostgreSQL**: `final-project-production-db` (Multi-AZ)
- ✅ **ECR Repository**: `final-project-ecr` з Django образами
- ✅ **VPC**: Ізольована мережа з 6 підмережами

**🚀 Розгорнуті сервіси з AWS URLs:**
- ✅ **Jenkins**: http://a016f3d06f8504012b4f4b9a13ebd33a-1981017016.eu-west-1.elb.amazonaws.com:8080
- ✅ **Argo CD**: https://a05fc9b53019d4e97b6470adb9ddee14-331120931.eu-west-1.elb.amazonaws.com
- ✅ **Grafana**: http://af6503eaf801a434b97d413d1df0241a-1422711606.eu-west-1.elb.amazonaws.com
- ✅ **Prometheus**: http://add504804b7d246a0bd5c576b6b7dd6c-1293644691.eu-west-1.elb.amazonaws.com:9090
- ✅ **Django App**: http://a40be67dd32e14e7bbd1588af4764378-416909794.eu-west-1.elb.amazonaws.com

**💾 Persistent Storage:**
- ✅ Jenkins, Prometheus, Grafana, Alertmanager PVCs (всього 65Gi)

**📈 Статистика:**
- **50+ AWS ресурсів** успішно розгорнуто
- **17 pods** працюють стабільно 
- **5 LoadBalancers** надають зовнішній доступ

**⏱️ Загальний час розгортання**: 20-25 хвилин