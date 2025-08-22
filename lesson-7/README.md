# Terraform Infrastructure with Kubernetes Project

## Опис проєкту

Цей проєкт використовує Terraform для створення та управління повною інфраструктурою AWS з Kubernetes кластером та Helm-чартами для деплою Django-застосунків. Проєкт організований з використанням модульної структури для забезпечення повторного використання коду та легкості обслуговування.

## Структура проєкту

```
lesson-7/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальне виведення ресурсів
├── README.md                # Документація проєкту
│
├── modules/                 # Каталог з усіма модулями
│   │
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf       # Виведення інформації про VPC
│   │
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf           # Створення ECR репозиторію
│   │   ├── variables.tf     # Змінні для ECR
│   │   └── outputs.tf       # Виведення URL репозиторію ECR
│   │
│   └── eks/                 # Модуль для Kubernetes кластера
│       ├── eks.tf           # Створення EKS кластера
│       ├── variables.tf     # Змінні для EKS
│       └── outputs.tf       # Виведення інформації про кластер
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

## Команди для роботи з проєктом

### Terraform команди

#### Ініціалізація проєкту
```bash
terraform init
```

#### Планування змін
```bash
terraform plan
```

#### Застосування змін
```bash
terraform apply
```

#### Знищення інфраструктури
```bash
terraform destroy
```

### Kubernetes та Helm команди

#### Підключення до EKS кластера
```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

#### Перевірка підключення
```bash
kubectl get nodes
```

#### Деплой Django застосунку через Helm
```bash
# Оновіть values.yaml з правильним ECR URL
helm upgrade --install django-app ./charts/django-app

# Перевірка статусу
helm list
kubectl get pods,services,hpa
```

#### Тестування автомасштабування
```bash
# Створення навантаження
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# В контейнері:
while true; do wget -q -O- http://django-app-django/; done
```

## Опис модулів

### 1. Модуль `s3-backend`

**Призначення:** Створення інфраструктури для зберігання стану Terraform.

**Ресурси:**
- **S3 Bucket** - зберігання файлів стану Terraform з шифруванням
- **DynamoDB Table** - блокування стану для запобігання конфліктам

### 2. Модуль `vpc`

**Призначення:** Створення мережевої інфраструктури для EKS кластера.

**Ресурси:**
- **VPC** - ізольована мережа
- **Public/Private Subnets** - підмережі у кількох зонах доступності
- **Internet Gateway & NAT Gateway** - забезпечення інтернет-доступу
- **Route Tables** - маршрутизація трафіку

### 3. Модуль `ecr`

**Призначення:** Репозиторій для Docker образів Django застосунку.

**Ресурси:**
- **ECR Repository** - приватний репозиторій з шифруванням
- **Lifecycle Policy** - автоматичне очищення старих образів
- **Scan Configuration** - сканування на вразливості

### 4. Модуль `eks`

**Призначення:** Створення Kubernetes кластера в AWS.

**Ресурси:**
- **EKS Cluster** - Kubernetes кластер
- **Node Groups** - групи worker nodes для запуску подів
- **IAM Roles & Policies** - права доступу для кластера та нодів
- **Security Groups** - мережева безпека
- **Add-ons** - додаткові компоненти (VPC CNI, CoreDNS, kube-proxy)

**Основні функції:**
- Автоматичні оновлення Kubernetes
- Інтеграція з AWS сервісами
- Високодоступна панель керування
- Автомасштабування нодів
- Моніторинг та логування

### 5. Helm чарт `django-app`

**Призначення:** Деплой Django застосунку з автомасштабуванням.

**Компоненти:**

#### `deployment.yaml`
- Розгортання Django подів з образу з ECR
- Підключення змінних середовища з ConfigMap
- Health checks (readiness/liveness probes)
- Ресурсні лімити для HPA

#### `service.yaml`
- LoadBalancer для зовнішнього доступу
- Проксування трафіку на порт 8000 Django

#### `configmap.yaml`
- Змінні середовища для Django
- Налаштування бази даних
- Конфігурація застосунку

#### `hpa.yaml`
- **Horizontal Pod Autoscaler**
- Автомасштабування від 2 до 6 подів
- Базується на CPU навантаженні > 70%
- Підтримка масштабування за пам'яттю

## Особливості автомасштабування

### HPA (Horizontal Pod Autoscaler)
```yaml
# Конфігурація в values.yaml
autoscaling:
  enabled: true
  minReplicas: 2      # Мінімум подів
  maxReplicas: 6      # Максимум подів
  targetCPUUtilizationPercentage: 70  # Поріг CPU
```

### Ресурсні вимоги (обов'язкові для HPA)
```yaml
resources:
  requests:
    cpu: 100m    # Мінімальні вимоги
    memory: 128Mi
  limits:
    cpu: 500m    # Максимальні лімити
    memory: 512Mi
```

## Передумови

1. **Terraform** (версія 1.0+)
2. **AWS CLI** з налаштованими правами доступу
3. **kubectl** для роботи з Kubernetes
4. **Helm** (версія 3.0+) для деплою застосунків
5. **Docker** образ Django у ECR репозиторії

## Покрокова інструкція з розгортання

### Крок 1: Створення інфраструктури
```bash
# Клонування та ініціалізація
git clone <repository-url>
cd lesson-7
terraform init

# Створення інфраструктури
terraform plan
terraform apply
```

### Крок 2: Підключення до EKS
```bash
# Отримання конфігурації кластера
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Перевірка підключення
kubectl get nodes
```

### Крок 3: Підготовка Docker образу
```bash
# Збірка та пуш образу в ECR
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <ecr-url>
docker build -t django-app .
docker tag django-app:latest <ecr-url>/django-app:latest
docker push <ecr-url>/django-app:latest
```

### Крок 4: Оновлення Helm конфігурації
```yaml
# У charts/django-app/values.yaml вкажіть правильний ECR URL
image:
  repository: <YOUR_ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/django-app
  tag: latest
```

### Крок 5: Деплой застосунку
```bash
# Встановлення Django через Helm
helm upgrade --install django-app ./charts/django-app

# Моніторинг деплою
kubectl get pods -w
helm status django-app
```

### Крок 6: Тестування
```bash
# Перевірка сервісів
kubectl get services

# Тестування автомасштабування
kubectl run load-generator --image=busybox -it --rm -- /bin/sh
# while true; do wget -q -O- http://django-app-django/; done

# Спостереження за HPA
kubectl get hpa -w
```

## Моніторинг та діагностика

### Корисні команди
```bash
# Статус Helm релізів
helm list

# Логи подів
kubectl logs -l app=django-app-django

# Статус HPA
kubectl describe hpa django-app-django-hpa

# Метрики ресурсів
kubectl top pods
kubectl top nodes

# Події кластера
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Масштабування та оновлення
```bash
# Ручне масштабування (тимчасово)
kubectl scale deployment django-app-django --replicas=4

# Оновлення конфігурації Helm
helm upgrade django-app ./charts/django-app --set image.tag=v1.1.0

# Откат релізу
helm rollback django-app 1
```

## Важливі зауваження

⚠️ **Увага:**
- EKS кластер коштує ~$0.10/годину тільки за панель керування
- LoadBalancer створює ELB (~$16-25/місяць)
- Worker nodes оплачуються як звичайні EC2 інстанси

🔒 **Безпека:**
- ECR репозиторій приватний з шифруванням
- EKS кластер використовує приватні підмережі
- IAM ролі з мінімальними правами

📈 **Масштабування:**
- HPA автоматично масштабує поди на основі метрик
- Cluster Autoscaler може додавати/видаляти nodes
- Моніторинг через CloudWatch

🚀 **Production Ready:**
- Health checks для високої доступності
- Resource limits для стабільної роботи
- LoadBalancer для зовнішнього доступу
- ConfigMap для гнучкої конфігурації

## Очищення ресурсів

```bash
# Видалення Helm релізів
helm uninstall django-app

# Знищення інфраструктури
terraform destroy
```

**Важливо:** Переконайтеся, що всі LoadBalancer'и видалено перед `terraform destroy`, інакше ELB може залишитися та продовжувати нараховувати кошти.
