# AI 世界开发环境配置与部署指南

## 📋 概述

本文档提供了搭建 AI 驱动虚拟世界开发环境的完整指南，包括本地开发环境、云端部署环境、CI/CD流水线以及团队协作工具的配置建议。

## 🖥️ 本地开发环境配置

### 1. 基础开发工具

#### 代码编辑器与IDE
```bash
# 推荐的编辑器配置
# 1. Visual Studio Code
curl -L "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" -o vscode.deb
sudo dpkg -i vscode.deb

# 2. 必需插件
code --install-extension ms-vscode.cpptools
code --install-extension ms-python.python
code --install-extension redhat.vscode-yaml
code --install-extension ms-vscode.vscode-json
code --install-extension bradlc.vscode-tailwindcss
code --install-extension esbenp.prettier-vscode
code --install-extension ms-vscode.vscode-git
```

#### 版本控制
```bash
# Git 配置
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase false

# Git LFS (大文件支持)
git lfs install
git lfs track "*.psd"
git lfs track "*.blend"
git lfs track "*.fbx"
git lfs track "*.wav"
git lfs track "*.mp3"
```

### 2. 游戏引擎环境

#### Godot 4.x 配置
```bash
# Ubuntu/Debian 安装
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:godot-team/godot
sudo apt update
sudo apt install godot4 godot4-export-templates

# macOS 安装
brew install --cask godot

# Windows 安装
# 从 https://godotengine.org/download 下载安装包
```

#### Godot 项目配置
```ini
# project.godot 关键配置
[application]

config/name="AI World"
config/description="AI-driven virtual world simulation"
config/version="1.0.0"
config/features=PackedStringArray("4.3", "Forward Plus")

[rendering]

renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true

[input]

# 自定义输入映射配置
```

### 3. AI 开发环境

#### Python 环境
```bash
# 创建虚拟环境
python3 -m venv ai-world-env
source ai-world-env/bin/activate  # Linux/macOS
# ai-world-env\Scripts\activate  # Windows

# 安装依赖
pip install openai anthropic
pip install torch torchvision torchaudio
pip install transformers accelerate
pip install numpy pandas matplotlib
pip install fastapi uvicorn
pip install websockets
pip install redis psycopg2-binary
pip install pytest pytest-asyncio
pip install black flake8 mypy
```

#### Node.js 环境 (可选)
```bash
# 使用 nvm 管理 Node.js 版本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# 安装依赖
npm install -g typescript ts-node
npm install express socket.io
npm install @types/node @types/express
```

### 4. 数据库环境

#### PostgreSQL
```bash
# Ubuntu/Debian 安装
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# 创建数据库和用户
sudo -u postgres psql
CREATE DATABASE ai_world;
CREATE USER ai_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE ai_world TO ai_user;
\q
```

#### Redis (缓存)
```bash
# Ubuntu/Debian 安装
sudo apt install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# 配置 Redis
sudo nano /etc/redis/redis.conf
# 设置 maxmemory 和内存策略
```

## 🌐 云端部署环境

### 1. 容器化配置

#### Dockerfile
```dockerfile
# Dockerfile for AI World Application
FROM godotengine/godot:4.3

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖
COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt

# 复制应用代码
COPY . /app
WORKDIR /app

# 构建游戏
RUN godot --headless --export "Linux/X11" ./build/ai-world.x86_64

# 运行时配置
EXPOSE 8080
CMD ["./build/ai-world.x86_64"]
```

#### docker-compose.yml
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://ai_user:password@db:5432/ai_world
      - REDIS_URL=redis://redis:6379
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    depends_on:
      - db
      - redis
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=ai_world
      - POSTGRES_USER=ai_user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app

volumes:
  postgres_data:
  redis_data:
```

### 2. 云服务配置

#### AWS 部署 (Terraform)
```hcl
# main.tf
provider "aws" {
  region = var.aws_region
}

# VPC 配置
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ai-world-vpc"
  }
}

# ECS 集群
resource "aws_ecs_cluster" "main" {
  name = "ai-world-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# RDS 数据库
resource "aws_db_instance" "main" {
  identifier     = "ai-world-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = "ai_world"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  tags = {
    Name = "ai-world-db"
  }
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "main" {
  name       = "ai-world-cache-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "ai-world-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
}
```

#### Kubernetes 配置
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-world-app
  labels:
    app: ai-world
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ai-world
  template:
    metadata:
      labels:
        app: ai-world
    spec:
      containers:
      - name: ai-world
        image: ai-world:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: ai-world-secrets
              key: database-url
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: ai-world-secrets
              key: openai-api-key
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: ai-world-service
spec:
  selector:
    app: ai-world
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

## 🔄 CI/CD 流水线

### 1. GitHub Actions 配置

#### .github/workflows/ci.yml
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: test_ai_world
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
    - uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-asyncio

    - name: Run linting
      run: |
        flake8 ai_server/
        black --check ai_server/
        mypy ai_server/

    - name: Run tests
      env:
        DATABASE_URL: postgresql://postgres:test_password@localhost:5432/test_ai_world
        REDIS_URL: redis://localhost:6379
        OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      run: |
        pytest tests/ -v --cov=ai_server --cov-report=xml

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'

    - name: Configure kubectl
      run: |
        echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/ai-world-app ai-world=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
        kubectl rollout status deployment/ai-world-app
```

### 2. 本地开发脚本

#### scripts/dev-setup.sh
```bash
#!/bin/bash

# AI World 开发环境设置脚本

set -e

echo "🚀 设置 AI World 开发环境..."

# 检查必需工具
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 未安装，请先安装 $1"
        exit 1
    else
        echo "✅ $1 已安装"
    fi
}

echo "📋 检查必需工具..."
check_tool "git"
check_tool "python3"
check_tool "node"
check_tool "docker"
check_tool "docker-compose"

# 设置 Python 虚拟环境
if [ ! -d "venv" ]; then
    echo "🐍 创建 Python 虚拟环境..."
    python3 -m venv venv
fi

echo "🔧 激活虚拟环境..."
source venv/bin/activate

# 安装 Python 依赖
echo "📦 安装 Python 依赖..."
pip install --upgrade pip
pip install -r requirements.txt

# 安装前端依赖
if [ -f "package.json" ]; then
    echo "📦 安装前端依赖..."
    npm install
fi

# 设置环境变量
if [ ! -f ".env" ]; then
    echo "⚙️ 创建环境变量文件..."
    cp .env.example .env
    echo "请编辑 .env 文件，设置必要的环境变量"
fi

# 启动数据库服务
echo "🗄️ 启动数据库服务..."
docker-compose up -d db redis

# 等待数据库启动
echo "⏳ 等待数据库启动..."
sleep 10

# 运行数据库迁移
echo "🔄 运行数据库迁移..."
python manage.py migrate

# 创建超级用户
echo "👤 创建管理员用户..."
python manage.py createsuperuser --noinput || true

echo "✅ 开发环境设置完成！"
echo ""
echo "🎯 下一步："
echo "1. 编辑 .env 文件，设置 API 密钥"
echo "2. 运行 'npm run dev' 启动前端开发服务器"
echo "3. 运行 'python manage.py runserver' 启动后端服务"
echo "4. 访问 http://localhost:8000 查看应用"
```

#### scripts/deploy.sh
```bash
#!/bin/bash

# 部署脚本

set -e

ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}

echo "🚀 部署 AI World 到 $ENVIRONMENT 环境 (版本: $VERSION)"

# 检查环境
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ 环境必须是 'staging' 或 'production'"
    exit 1
fi

# 设置配置
case $ENVIRONMENT in
    "staging")
        KUBECONFIG="kubeconfig-staging"
        NAMESPACE="ai-world-staging"
        ;;
    "production")
        KUBECONFIG="kubeconfig-prod"
        NAMESPACE="ai-world-prod"
        ;;
esac

echo "📦 构建 Docker 镜像..."
docker build -t ai-world:$VERSION .

echo "🏷️ 标记镜像..."
docker tag ai-world:$VERSION registry.example.com/ai-world:$VERSION

echo "📤 推送镜像..."
docker push registry.example.com/ai-world:$VERSION

echo "⚙️ 更新 Kubernetes 配置..."
export KUBECONFIG=$KUBECONFIG
kubectl config use-context $ENVIRONMENT

echo "🔄 部署应用..."
kubectl set image deployment/ai-world-app ai-world=registry.example.com/ai-world:$VERSION -n $NAMESPACE

echo "⏳ 等待部署完成..."
kubectl rollout status deployment/ai-world-app -n $NAMESPACE

echo "✅ 部署完成！"
echo ""
echo "🔍 检查部署状态："
echo "kubectl get pods -n $NAMESPACE"
echo "kubectl logs -f deployment/ai-world-app -n $NAMESPACE"
```

## 👥 团队协作工具

### 1. 代码规范

#### .pre-commit-config.yaml
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/psf/black
    rev: 23.7.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        args: [--max-line-length=88, --extend-ignore=E203]

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: [--profile=black]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.5.1
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
```

### 2. 项目文档结构

```
docs/
├── development/              # 开发文档
│   ├── getting-started.md
│   ├── coding-standards.md
│   └── testing-guide.md
├── deployment/               # 部署文档
│   ├── environments.md
│   ├── monitoring.md
│   └── troubleshooting.md
├── api/                      # API 文档
│   ├── openapi.yaml
│   └── examples/
└── architecture/             # 架构文档
    ├── system-design.md
    ├── database-schema.md
    └── security.md
```

### 3. 开发工作流

#### Git 工作流
```bash
# 功能开发流程
git checkout develop
git pull origin develop
git checkout -b feature/new-ai-feature

# 开发完成后
git add .
git commit -m "feat: add new AI feature"
git push origin feature/new-ai-feature

# 创建 Pull Request
# 代码审查通过后合并到 develop

# 发布流程
git checkout main
git merge develop
git tag v1.1.0
git push origin main --tags
```

## 🔧 故障排除指南

### 常见问题

#### 1. Python 依赖问题
```bash
# 重新安装依赖
pip uninstall -r requirements.txt -y
pip install -r requirements.txt

# 清理 pip 缓存
pip cache purge
```

#### 2. 数据库连接问题
```bash
# 检查数据库状态
docker-compose ps db

# 查看数据库日志
docker-compose logs db

# 重启数据库
docker-compose restart db
```

#### 3. Docker 问题
```bash
# 清理 Docker 资源
docker system prune -a

# 重新构建镜像
docker-compose build --no-cache

# 查看容器日志
docker-compose logs app
```

### 性能调优

#### 1. 数据库优化
```sql
-- 创建索引
CREATE INDEX idx_character_created_at ON characters(created_at);
CREATE INDEX idx_memory_importance ON memories(importance DESC, created_at DESC);

-- 分析查询性能
EXPLAIN ANALYZE SELECT * FROM memories WHERE character_id = 'xxx' ORDER BY importance DESC;
```

#### 2. Redis 缓存优化
```bash
# 监控 Redis 性能
redis-cli monitor

# 检查内存使用
redis-cli info memory

# 优化配置
echo "maxmemory 256mb" >> redis.conf
echo "maxmemory-policy allkeys-lru" >> redis.conf
```

---

_文档版本: v1.0_
_最后更新: 2024-11-10_
_维护者: AI开发团队_

这份开发环境配置指南涵盖了从本地开发到云端部署的完整流程，为AI世界项目的开发提供了坚实的基础设施支持。