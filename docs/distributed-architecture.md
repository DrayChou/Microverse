# 分布式 AI 世界架构设计

## 📋 概述

分布式架构是构建大规模、高可用 AI 虚拟世界的核心技术。本文档详细介绍了从单机到集群、从微服务到云原生的完整架构演进路径，包括负载均衡、容错机制、弹性扩展等关键技术。

### 🎯 架构目标

- **高可用性**: 99.9%+ 服务可用性，故障自动恢复
- **可扩展性**: 支持 100,000+ 并发用户，水平扩展
- **低延迟**: 全球用户 < 100ms 响应时间
- **容错性**: 单点故障不影响整体服务
- **一致性**: 分布式数据一致性保证

## 🏗️ 架构演进路径

### 1. 阶段一：单机架构 → 微服务架构

#### 1.1 当前单机架构分析

```mermaid
graph TB
    subgraph "单机架构"
        A[Godot客户端] --> B[游戏服务器]
        B --> C[AI服务]
        B --> D[数据库]
        B --> E[缓存]
    end

    subgraph "问题"
        F["单点故障"]
        G["扩展困难"]
        H["维护复杂"]
    end

    B -.-> F
    B -.-> G
    B -.-> H
```

**当前架构局限性**:
- 所有服务集中在一台服务器
- AI 计算密集型任务阻塞其他服务
- 数据库连接池限制并发用户数
- 难以针对不同服务进行优化

#### 1.2 微服务架构设计

```mermaid
graph TB
    subgraph "客户端层"
        A[Web客户端] --> LB[负载均衡器]
        B[移动客户端] --> LB
        C[VR客户端] --> LB
    end

    subgraph "API网关层"
        LB --> GW[API Gateway]
        GW --> Auth[认证服务]
        GW --> Rate[限流服务]
        GW --> Log[日志服务]
    end

    subgraph "微服务层"
        Auth --> MS1[用户服务]
        Auth --> MS2[世界服务]
        Auth --> MS3[角色服务]
        Auth --> MS4[对话服务]
        Auth --> MS5[任务服务]
    end

    subgraph "AI服务层"
        MS4 --> AI1[对话AI]
        MS2 --> AI2[决策AI]
        MS3 --> AI3[行为AI]
        MS5 --> AI4[任务AI]
    end

    subgraph "数据层"
        MS1 --> DB1[(用户数据库)]
        MS2 --> DB2[(世界数据库)]
        MS3 --> DB3[(角色数据库)]
        MS4 --> Cache1[(对话缓存)]
        MS5 --> Cache2[(任务缓存)]
    end
```

### 2. 阶段二：服务拆分策略

#### 2.1 核心服务划分

```yaml
# services/service-catalog.yaml
services:
  gateway:
    name: "api-gateway"
    version: "1.0.0"
    description: "统一API网关"
    responsibilities:
      - 请求路由
      - 认证授权
      - 限流熔断
      - 监控日志
    resources:
      cpu: "500m"
      memory: "512Mi"
      replicas: 3

  user-service:
    name: "user-service"
    version: "1.0.0"
    description: "用户管理服务"
    responsibilities:
      - 用户注册登录
      - 个人资料管理
      - 偏好设置
      - 权限控制
    resources:
      cpu: "300m"
      memory: "256Mi"
      replicas: 2
    database:
      type: "postgresql"
      connection_pool: 10

  world-service:
    name: "world-service"
    version: "1.0.0"
    description: "世界状态管理"
    responsibilities:
      - 世界状态同步
      - 环境变化计算
      - 事件分发
      - 持久化
    resources:
      cpu: "1000m"
      memory: "1Gi"
      replicas: 3
    database:
      type: "redis-cluster"
      shard_count: 6

  character-service:
    name: "character-service"
    version: "1.0.0"
    description: "角色行为管理"
    responsibilities:
      - 角色状态管理
      - 行为决策
      - 记忆管理
      - 关系网络
    resources:
      cpu: "800m"
      memory: "2Gi"
      replicas: 5
    database:
      type: "mongodb"
      shard_count: 4

  ai-service:
    name: "ai-service"
    version: "1.0.0"
    description: "AI计算服务"
    responsibilities:
      - 语言模型调用
      - 多模态处理
      - 决策计算
      - 情感分析
    resources:
      cpu: "2000m"
      memory: "4Gi"
      replicas: 8
    gpu: true
    dependencies:
      - "openai-api"
      - "huggingface"
      - "local-models"

  conversation-service:
    name: "conversation-service"
    version: "1.0.0"
    description: "对话管理服务"
    responsibilities:
      - 对话状态管理
      - 消息路由
      - 历史记录
      - 实时推送
    resources:
      cpu: "500m"
      memory: "512Mi"
      replicas: 3
    database:
      type: "redis"
      cluster: true
```

#### 2.2 服务间通信设计

```python
# services/communication/service_discovery.py
import consul
import aiohttp
import asyncio
from typing import Dict, List, Optional

class ServiceDiscovery:
    def __init__(self, consul_host: str = "localhost", consul_port: int = 8500):
        self.consul = consul.Consul(host=consul_host, port=consul_port)
        self.service_cache = {}
        self.http_session = aiohttp.ClientSession()

    async def register_service(self, service_name: str, service_id: str,
                             address: str, port: int, health_check_url: str):
        """注册服务"""
        self.consul.agent.service.register(
            name=service_name,
            service_id=service_id,
            address=address,
            port=port,
            check=consul.Check.http(f"http://{address}:{port}{health_check_url}",
                                   interval="10s")
        )

    async def discover_service(self, service_name: str) -> List[Dict]:
        """发现服务"""
        if service_name in self.service_cache:
            return self.service_cache[service_name]

        _, services = self.consul.health.service(service_name, passing=True)
        service_instances = [
            {
                "address": service['Service']['Address'],
                "port": service['Service']['Port'],
                "service_id": service['Service']['ID']
            }
            for service in services
        ]

        self.service_cache[service_name] = service_instances
        return service_instances

    async def call_service(self, service_name: str, endpoint: str,
                          method: str = "GET", **kwargs) -> Dict:
        """调用其他服务"""
        services = await self.discover_service(service_name)
        if not services:
            raise ServiceNotAvailableException(f"Service {service_name} not available")

        # 负载均衡：轮询
        service = services[hash(endpoint) % len(services)]
        url = f"http://{service['address']}:{service['port']}{endpoint}"

        async with self.http_session.request(method, url, **kwargs) as response:
            return await response.json()
```

```python
# services/communication/message_queue.py
import aiokafka
import asyncio
import json
from typing import Dict, Callable, Any

class MessageQueue:
    def __init__(self, bootstrap_servers: str):
        self.bootstrap_servers = bootstrap_servers
        self.producer = None
        self.consumers = {}
        self.handlers = {}

    async def start(self):
        """启动消息队列"""
        self.producer = aiokafka.AIOKafkaProducer(
            bootstrap_servers=self.bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        await self.producer.start()

    async def publish_event(self, topic: str, event: Dict):
        """发布事件"""
        await self.producer.send_and_wait(topic, event)

    async def subscribe_to_topic(self, topic: str, handler: Callable):
        """订阅主题"""
        if topic not in self.consumers:
            consumer = aiokafka.AIOKafkaConsumer(
                topic,
                bootstrap_servers=self.bootstrap_servers,
                value_deserializer=lambda v: json.loads(v.decode('utf-8'))
            )
            await consumer.start()
            self.consumers[topic] = consumer

        self.handlers[topic] = handler
        asyncio.create_task(self._consume_messages(topic))

    async def _consume_messages(self, topic: str):
        """消费消息"""
        consumer = self.consumers[topic]
        handler = self.handlers[topic]

        async for message in consumer:
            try:
                await handler(message.value)
            except Exception as e:
                print(f"Error processing message: {e}")

# 事件定义
class WorldEvents:
    CHARACTER_MOVED = "character.moved"
    CHARACTER_SPOKE = "character.spoke"
    TASK_COMPLETED = "task.completed"
    WORLD_STATE_CHANGED = "world.state_changed"
    AI_DECISION_MADE = "ai.decision_made"
```

### 3. 阶段三：云原生架构

#### 3.1 Kubernetes 部署配置

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ai-world
  labels:
    name: ai-world

---
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-world-config
  namespace: ai-world
data:
  database_host: "postgres-cluster.default.svc.cluster.local"
  redis_host: "redis-cluster.default.svc.cluster.local"
  kafka_host: "kafka-cluster.default.svc.cluster.local"
  log_level: "INFO"
  environment: "production"

---
# k8s/user-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: ai-world
  labels:
    app: user-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: ai-world/user-service:latest
        ports:
        - containerPort: 8001
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: ai-world-config
              key: redis_host
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
            port: 8001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: ai-world
spec:
  selector:
    app: user-service
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8001
  type: ClusterIP

---
# k8s/ai-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-service
  namespace: ai-world
spec:
  replicas: 8
  template:
    spec:
      containers:
      - name: ai-service
        image: ai-world/ai-service:latest
        resources:
          requests:
            memory: "4Gi"
            cpu: "2000m"
            nvidia.com/gpu: 1
          limits:
            memory: "8Gi"
            cpu: "4000m"
            nvidia.com/gpu: 1
        env:
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: ai-credentials
              key: openai_key
        - name: CUDA_VISIBLE_DEVICES
          value: "0"
      nodeSelector:
        accelerator: nvidia-tesla-v100
```

#### 3.2 服务网格 (Istio) 配置

```yaml
# istio/gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ai-world-gateway
  namespace: ai-world
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - ai-world.example.com
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: ai-world-tls
    hosts:
    - ai-world.example.com

---
# istio/virtual-service.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ai-world-routing
  namespace: ai-world
spec:
  hosts:
  - ai-world.example.com
  gateways:
  - ai-world-gateway
  http:
  - match:
    - uri:
        prefix: "/api/v1/users"
    route:
    - destination:
        host: user-service
        port:
          number: 80
    timeout: 5s
    retries:
      attempts: 3
      perTryTimeout: 2s
  - match:
    - uri:
        prefix: "/api/v1/characters"
    route:
    - destination:
        host: character-service
        port:
          number: 80
    timeout: 10s
    fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
  - match:
    - uri:
        prefix: "/api/v1/ai"
    route:
    - destination:
        host: ai-service
        port:
          number: 80
    timeout: 30s
    circuitBreaker:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s

---
# istio/destination-rule.yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ai-world-destinations
  namespace: ai-world
spec:
  host: user-service
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 10
    circuitBreaker:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
---
  host: ai-service
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    connectionPool:
      tcp:
        maxConnections: 50
      http:
        http1MaxPendingRequests: 25
```

## 🚀 核心技术实现

### 1. 负载均衡与流量管理

#### 1.1 智能负载均衡器

```python
# services/loadbalancer/intelligent_balancer.py
import asyncio
import aioredis
from typing import Dict, List, Optional
from dataclasses import dataclass
import time

@dataclass
class ServiceInstance:
    id: str
    address: str
    port: int
    weight: int
    current_load: float
    max_capacity: int
    health_score: float
    last_health_check: float

class IntelligentLoadBalancer:
    def __init__(self, redis_url: str):
        self.redis = aioredis.from_url(redis_url)
        self.instances: Dict[str, List[ServiceInstance]] = {}
        self.weights = {}

    async def add_instance(self, service_name: str, instance: ServiceInstance):
        """添加服务实例"""
        if service_name not in self.instances:
            self.instances[service_name] = []
        self.instances[service_name].append(instance)

    async def select_instance(self, service_name: str,
                            request_context: Dict = None) -> Optional[ServiceInstance]:
        """智能选择实例"""
        instances = self.instances.get(service_name, [])
        if not instances:
            return None

        # 基于多个因子计算最优实例
        best_instance = None
        best_score = -1

        for instance in instances:
            score = await self._calculate_instance_score(instance, request_context)
            if score > best_score:
                best_score = score
                best_instance = instance

        return best_instance

    async def _calculate_instance_score(self, instance: ServiceInstance,
                                      context: Dict = None) -> float:
        """计算实例得分"""
        # 基础权重
        score = instance.weight

        # 负载因子 (负载越低得分越高)
        load_factor = 1.0 - (instance.current_load / instance.max_capacity)
        score *= load_factor

        # 健康因子
        score *= instance.health_score

        # 地理位置因子 (如果有用户位置信息)
        if context and "user_location" in context:
            geo_factor = self._calculate_geo_factor(instance, context["user_location"])
            score *= geo_factor

        # 响应时间因子
        response_time = await self._get_average_response_time(instance.id)
        if response_time:
            time_factor = 1.0 / (1.0 + response_time / 1000.0)  # 转换为秒
            score *= time_factor

        return score

    async def update_instance_load(self, instance_id: str, load_delta: float):
        """更新实例负载"""
        for service_instances in self.instances.values():
            for instance in service_instances:
                if instance.id == instance_id:
                    instance.current_load += load_delta
                    break
```

#### 1.2 熔断器模式实现

```python
# services/resilience/circuit_breaker.py
import asyncio
import time
from enum import Enum
from typing import Callable, Any
import logging

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(self,
                 failure_threshold: int = 5,
                 recovery_timeout: int = 60,
                 expected_exception: type = Exception):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception

        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED

        self.logger = logging.getLogger(__name__)

    async def call(self, func: Callable, *args, **kwargs) -> Any:
        """执行被保护的函数"""
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
            else:
                raise CircuitBreakerOpenException("Circuit breaker is OPEN")

        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result
        except self.expected_exception as e:
            self._on_failure()
            raise e

    def _on_success(self):
        """成功时的处理"""
        self.failure_count = 0
        self.state = CircuitState.CLOSED

    def _on_failure(self):
        """失败时的处理"""
        self.failure_count += 1
        self.last_failure_time = time.time()

        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
            self.logger.warning(f"Circuit breaker OPEN due to {self.failure_count} failures")

    def _should_attempt_reset(self) -> bool:
        """是否应该尝试重置"""
        return (self.last_failure_time and
                time.time() - self.last_failure_time >= self.recovery_timeout)

class CircuitBreakerOpenException(Exception):
    """熔断器开启异常"""
    pass

# 装饰器版本
def circuit_breaker(circuit_breaker_instance: CircuitBreaker):
    """熔断器装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            return await circuit_breaker_instance.call(func, *args, **kwargs)
        return wrapper
    return decorator
```

### 2. 数据一致性保证

#### 2.1 分布式事务管理

```python
# services/transaction/distributed_transaction.py
import asyncio
import uuid
from typing import List, Dict, Callable, Any
from enum import Enum
import json
import time

class TransactionStatus(Enum):
    PENDING = "pending"
    COMMITTED = "committed"
    ABORTED = "aborted"

class SagaTransaction:
    def __init__(self, transaction_id: str = None):
        self.transaction_id = transaction_id or str(uuid.uuid4())
        self.steps: List[TransactionStep] = []
        self.status = TransactionStatus.PENDING
        self.compensations: List[Callable] = []

    def add_step(self, action: Callable, compensation: Callable,
                 rollback_params: Dict = None):
        """添加事务步骤"""
        step = TransactionStep(
            action=action,
            compensation=compensation,
            rollback_params=rollback_params or {}
        )
        self.steps.append(step)

    async def execute(self) -> bool:
        """执行Saga事务"""
        executed_steps = []

        try:
            # 执行所有步骤
            for i, step in enumerate(self.steps):
                result = await step.action()
                executed_steps.append((i, step, result))
                self.logger.info(f"Step {i} executed successfully")

            # 所有步骤成功，提交事务
            self.status = TransactionStatus.COMMITTED
            return True

        except Exception as e:
            self.logger.error(f"Transaction failed: {e}")
            self.status = TransactionStatus.ABORTED

            # 补偿已执行的步骤
            await self._compensate(executed_steps)
            return False

    async def _compensate(self, executed_steps: List[tuple]):
        """补偿已执行的步骤"""
        # 逆序补偿
        for step_index, step, result in reversed(executed_steps):
            try:
                await step.compensation(result, **step.rollback_params)
                self.logger.info(f"Step {step_index} compensated successfully")
            except Exception as e:
                self.logger.error(f"Failed to compensate step {step_index}: {e}")

class TransactionStep:
    def __init__(self, action: Callable, compensation: Callable,
                 rollback_params: Dict = None):
        self.action = action
        self.compensation = compensation
        self.rollback_params = rollback_params

# 分布式事务协调器
class DistributedTransactionCoordinator:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.active_transactions = {}

    async def begin_transaction(self) -> SagaTransaction:
        """开始分布式事务"""
        transaction = SagaTransaction()
        self.active_transactions[transaction.transaction_id] = transaction

        # 持久化事务状态
        await self._persist_transaction_state(transaction)

        return transaction

    async def commit_transaction(self, transaction: SagaTransaction) -> bool:
        """提交事务"""
        success = await transaction.execute()

        # 更新持久化状态
        await self._update_transaction_status(transaction.transaction_id, transaction.status)

        # 清理活跃事务
        if transaction.transaction_id in self.active_transactions:
            del self.active_transactions[transaction.transaction_id]

        return success

    async def _persist_transaction_state(self, transaction: SagaTransaction):
        """持久化事务状态"""
        state = {
            "transaction_id": transaction.transaction_id,
            "status": transaction.status.value,
            "steps_count": len(transaction.steps),
            "created_at": time.time()
        }

        await self.redis.hset(
            f"transaction:{transaction.transaction_id}",
            mapping=state
        )
        await self.redis.expire(f"transaction:{transaction.transaction_id}", 3600)
```

#### 2.2 数据分片策略

```python
# services/sharding/sharding_manager.py
import hashlib
import bisect
from typing import Dict, List, Any, Optional
from dataclasses import dataclass

@dataclass
class Shard:
    id: str
    host: str
    port: int
    weight: int
    range_start: Optional[int] = None
    range_end: Optional[int] = None

class ConsistentHashRing:
    def __init__(self, virtual_nodes: int = 150):
        self.virtual_nodes = virtual_nodes
        self.ring = {}
        self.sorted_keys = []
        self.shards = {}

    def add_shard(self, shard: Shard):
        """添加分片"""
        self.shards[shard.id] = shard

        # 添加虚拟节点
        for i in range(self.virtual_nodes):
            key = self._hash_key(f"{shard.id}:{i}")
            self.ring[key] = shard.id

        # 重新排序
        self.sorted_keys = sorted(self.ring.keys())

    def remove_shard(self, shard_id: str):
        """移除分片"""
        if shard_id in self.shards:
            del self.shards[shard_id]

            # 移除虚拟节点
            keys_to_remove = []
            for key, sid in self.ring.items():
                if sid == shard_id:
                    keys_to_remove.append(key)

            for key in keys_to_remove:
                del self.ring[key]

            self.sorted_keys = sorted(self.ring.keys())

    def get_shard(self, key: str) -> Optional[Shard]:
        """获取键对应的分片"""
        if not self.ring:
            return None

        hash_key = self._hash_key(key)

        # 找到第一个大于等于hash_key的节点
        index = bisect.bisect_right(self.sorted_keys, hash_key)
        if index == len(self.sorted_keys):
            index = 0

        node_key = self.sorted_keys[index]
        shard_id = self.ring[node_key]

        return self.shards.get(shard_id)

    def _hash_key(self, key: str) -> int:
        """计算哈希值"""
        return int(hashlib.md5(key.encode()).hexdigest(), 16)

class ShardingManager:
    def __init__(self):
        self.hash_ring = ConsistentHashRing()
        self.range_shards = {}

    def add_hash_shard(self, shard: Shard):
        """添加哈希分片"""
        self.hash_ring.add_shard(shard)

    def add_range_shard(self, shard: Shard):
        """添加范围分片"""
        if shard.range_start is None or shard.range_end is None:
            raise ValueError("Range shard must have range_start and range_end")

        self.range_shards[shard.id] = shard

    def get_shard_for_key(self, key: str, sharding_strategy: str = "hash") -> Optional[Shard]:
        """根据键获取分片"""
        if sharding_strategy == "hash":
            return self.hash_ring.get_shard(key)
        elif sharding_strategy == "range":
            return self._get_range_shard(key)
        else:
            raise ValueError(f"Unknown sharding strategy: {sharding_strategy}")

    def _get_range_shard(self, key: str) -> Optional[Shard]:
        """获取范围分片"""
        # 简化实现：基于key的哈希值的数字部分
        try:
            key_number = int(hashlib.md5(key.encode()).hexdigest()[:8], 16)
        except:
            key_number = 0

        for shard in self.range_shards.values():
            if shard.range_start <= key_number <= shard.range_end:
                return shard

        return None

# 使用示例
class DatabaseService:
    def __init__(self):
        self.sharding_manager = ShardingManager()
        self._setup_shards()

    def _setup_shards(self):
        """设置分片"""
        # 哈希分片
        for i in range(4):
            shard = Shard(
                id=f"hash_shard_{i}",
                host=f"db-node-{i}.example.com",
                port=5432,
                weight=1
            )
            self.sharding_manager.add_hash_shard(shard)

        # 范围分片
        ranges = [(0, 0x3fffffff), (0x40000000, 0x7fffffff)]
        for i, (start, end) in enumerate(ranges):
            shard = Shard(
                id=f"range_shard_{i}",
                host=f"range-db-{i}.example.com",
                port=5432,
                weight=1,
                range_start=start,
                range_end=end
            )
            self.sharding_manager.add_range_shard(shard)

    async def get_character_data(self, character_id: str) -> Dict:
        """获取角色数据"""
        # 根据character_id选择分片
        shard = self.sharding_manager.get_shard_for_key(character_id, "hash")

        if shard:
            return await self._query_shard(shard, f"SELECT * FROM characters WHERE id = '{character_id}'")
        else:
            raise Exception("No available shard for character")
```

### 3. 监控与可观测性

#### 3.1 分布式链路追踪

```python
# services/observability/tracing.py
import time
import uuid
from typing import Dict, Any, Optional
from dataclasses import dataclass, field
import json
import asyncio

@dataclass
class Span:
    trace_id: str
    span_id: str
    parent_span_id: Optional[str]
    operation_name: str
    start_time: float
    end_time: Optional[float] = None
    tags: Dict[str, Any] = field(default_factory=dict)
    logs: List[Dict] = field(default_factory=list)

class DistributedTracer:
    def __init__(self):
        self.active_spans = {}
        self.span_collector = SpanCollector()

    def start_span(self, operation_name: str, parent_span: Span = None) -> Span:
        """开始新的span"""
        trace_id = parent_span.trace_id if parent_span else str(uuid.uuid4())
        span_id = str(uuid.uuid4())
        parent_span_id = parent_span.span_id if parent_span else None

        span = Span(
            trace_id=trace_id,
            span_id=span_id,
            parent_span_id=parent_span_id,
            operation_name=operation_name,
            start_time=time.time()
        )

        self.active_spans[span_id] = span
        return span

    def finish_span(self, span: Span, tags: Dict = None):
        """结束span"""
        span.end_time = time.time()
        if tags:
            span.tags.update(tags)

        # 发送到收集器
        asyncio.create_task(self.span_collector.collect_span(span))

        # 从活跃span中移除
        if span.span_id in self.active_spans:
            del self.active_spans[span.span_id]

    def add_tag(self, span: Span, key: str, value: Any):
        """添加标签"""
        span.tags[key] = value

    def log_event(self, span: Span, event: Dict):
        """记录事件"""
        event["timestamp"] = time.time()
        span.logs.append(event)

class SpanCollector:
    def __init__(self):
        self.export_buffer = []
        self.export_interval = 10  # 10秒
        self.buffer_size = 100

    async def collect_span(self, span: Span):
        """收集span"""
        self.export_buffer.append(span)

        if len(self.export_buffer) >= self.buffer_size:
            await self._export_spans()

    async def _export_spans(self):
        """导出span数据"""
        if not self.export_buffer:
            return

        spans_to_export = self.export_buffer.copy()
        self.export_buffer.clear()

        # 转换为Jaeger格式
        jaeger_spans = []
        for span in spans_to_export:
            jaeger_span = {
                "traceID": span.trace_id,
                "spanID": span.span_id,
                "parentSpanID": span.parent_span_id,
                "operationName": span.operation_name,
                "startTime": int(span.start_time * 1000000),  # 微秒
                "duration": int((span.end_time - span.start_time) * 1000000),
                "tags": [{"key": k, "value": str(v)} for k, v in span.tags.items()],
                "logs": span.logs
            }
            jaeger_spans.append(jaeger_span)

        # 发送到Jaeger
        await self._send_to_jaeger(jaeger_spans)

    async def _send_to_jaeger(self, spans: List[Dict]):
        """发送到Jaeger收集器"""
        import aiohttp

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    "http://jaeger-collector:14268/api/traces",
                    json={"data": spans}
                ) as response:
                    if response.status != 202:
                        print(f"Failed to send traces: {response.status}")
        except Exception as e:
            print(f"Error sending traces: {e}")

# 装饰器
def trace_operation(operation_name: str = None):
    """追踪操作装饰器"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            tracer = DistributedTracer()

            # 获取操作名称
            op_name = operation_name or f"{func.__module__}.{func.__name__}"

            # 开始span
            span = tracer.start_span(op_name)

            try:
                # 添加函数参数标签
                tracer.add_tag(span, "function.name", func.__name__)
                tracer.add_tag(span, "function.module", func.__module__)

                result = await func(*args, **kwargs)

                # 添加成功标签
                tracer.add_tag(span, "success", True)

                return result

            except Exception as e:
                # 添加错误标签
                tracer.add_tag(span, "success", False)
                tracer.add_tag(span, "error", str(e))
                tracer.log_event(span, {"event": "error", "error": str(e)})

                raise

            finally:
                # 结束span
                tracer.finish_span(span)

        return wrapper
    return decorator
```

#### 3.2 指标收集与告警

```python
# services/observability/metrics.py
import time
import asyncio
from typing import Dict, Any, List
from collections import defaultdict, deque
import prometheus_client as prom

class MetricsCollector:
    def __init__(self):
        # Prometheus 指标
        self.request_count = prom.Counter(
            'ai_world_requests_total',
            'Total requests',
            ['method', 'endpoint', 'status']
        )

        self.request_duration = prom.Histogram(
            'ai_world_request_duration_seconds',
            'Request duration',
            ['method', 'endpoint'],
            buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0]
        )

        self.active_connections = prom.Gauge(
            'ai_world_active_connections',
            'Active connections'
        )

        self.ai_response_time = prom.Histogram(
            'ai_world_ai_response_time_seconds',
            'AI service response time',
            ['model', 'operation'],
            buckets=[0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0]
        )

        self.error_rate = prom.Gauge(
            'ai_world_error_rate',
            'Error rate percentage',
            ['service']
        )

    def record_request(self, method: str, endpoint: str, status: int, duration: float):
        """记录请求指标"""
        self.request_count.labels(method=method, endpoint=endpoint, status=status).inc()
        self.request_duration.labels(method=method, endpoint=endpoint).observe(duration)

    def record_ai_response(self, model: str, operation: str, duration: float):
        """记录AI响应时间"""
        self.ai_response_time.labels(model=model, operation=operation).observe(duration)

    def update_active_connections(self, count: int):
        """更新活跃连接数"""
        self.active_connections.set(count)

    def update_error_rate(self, service: str, rate: float):
        """更新错误率"""
        self.error_rate.labels(service=service).set(rate)

class AlertManager:
    def __init__(self):
        self.alert_rules = []
        self.alert_history = deque(maxlen=1000)
        self.notification_channels = []

    def add_alert_rule(self, rule: 'AlertRule'):
        """添加告警规则"""
        self.alert_rules.append(rule)

    async def check_alerts(self, metrics: Dict[str, Any]):
        """检查告警"""
        for rule in self.alert_rules:
            if rule.should_alert(metrics):
                alert = Alert(
                    name=rule.name,
                    severity=rule.severity,
                    message=rule.generate_message(metrics),
                    timestamp=time.time()
                )

                await self._handle_alert(alert)

    async def _handle_alert(self, alert: 'Alert'):
        """处理告警"""
        self.alert_history.append(alert)

        # 发送通知
        for channel in self.notification_channels:
            await channel.send_notification(alert)

class AlertRule:
    def __init__(self, name: str, condition: str, severity: str = "warning"):
        self.name = name
        self.condition = condition
        self.severity = severity

    def should_alert(self, metrics: Dict[str, Any]) -> bool:
        """检查是否应该告警"""
        # 简化实现
        if self.name == "high_error_rate":
            error_rate = metrics.get("error_rate", 0)
            return error_rate > 5.0  # 错误率超过5%

        elif self.name == "high_response_time":
            response_time = metrics.get("avg_response_time", 0)
            return response_time > 2.0  # 响应时间超过2秒

        return False

    def generate_message(self, metrics: Dict[str, Any]) -> str:
        """生成告警消息"""
        if self.name == "high_error_rate":
            return f"错误率过高: {metrics.get('error_rate', 0):.2f}%"

        elif self.name == "high_response_time":
            return f"响应时间过长: {metrics.get('avg_response_time', 0):.2f}s"

        return f"告警: {self.name}"

@dataclass
class Alert:
    name: str
    severity: str
    message: str
    timestamp: float

class NotificationChannel:
    async def send_notification(self, alert: Alert):
        """发送通知"""
        raise NotImplementedError

class SlackNotificationChannel(NotificationChannel):
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url

    async def send_notification(self, alert: Alert):
        """发送Slack通知"""
        import aiohttp

        payload = {
            "text": f"🚨 告警: {alert.name}",
            "attachments": [
                {
                    "color": "danger" if alert.severity == "critical" else "warning",
                    "fields": [
                        {"title": "严重程度", "value": alert.severity, "short": True},
                        {"title": "时间", "value": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(alert.timestamp)), "short": True},
                        {"title": "详情", "value": alert.message, "short": False}
                    ]
                }
            ]
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(self.webhook_url, json=payload) as response:
                if response.status != 200:
                    print(f"Failed to send Slack notification: {response.status}")
```

## 📈 性能优化策略

### 1. 缓存架构

```python
# services/cache/multilevel_cache.py
import asyncio
import aioredis
import pickle
from typing import Any, Optional, Dict
from abc import ABC, abstractmethod

class CacheLevel(ABC):
    @abstractmethod
    async def get(self, key: str) -> Optional[Any]:
        pass

    @abstractmethod
    async def set(self, key: str, value: Any, ttl: int = 3600):
        pass

    @abstractmethod
    async def delete(self, key: str):
        pass

class L1Cache(CacheLevel):
    """内存缓存 (L1)"""
    def __init__(self, max_size: int = 1000):
        self.cache = {}
        self.max_size = max_size
        self.access_order = []

    async def get(self, key: str) -> Optional[Any]:
        if key in self.cache:
            # 更新访问顺序
            self.access_order.remove(key)
            self.access_order.append(key)
            return self.cache[key]
        return None

    async def set(self, key: str, value: Any, ttl: int = 3600):
        if len(self.cache) >= self.max_size:
            # 移除最少使用的项
            oldest_key = self.access_order.pop(0)
            del self.cache[oldest_key]

        self.cache[key] = value
        self.access_order.append(key)

    async def delete(self, key: str):
        if key in self.cache:
            del self.cache[key]
            self.access_order.remove(key)

class L2Cache(CacheLevel):
    """Redis缓存 (L2)"""
    def __init__(self, redis_url: str):
        self.redis = aioredis.from_url(redis_url)

    async def get(self, key: str) -> Optional[Any]:
        try:
            data = await self.redis.get(key)
            if data:
                return pickle.loads(data)
        except Exception as e:
            print(f"Redis get error: {e}")
        return None

    async def set(self, key: str, value: Any, ttl: int = 3600):
        try:
            data = pickle.dumps(value)
            await self.redis.setex(key, ttl, data)
        except Exception as e:
            print(f"Redis set error: {e}")

    async def delete(self, key: str):
        try:
            await self.redis.delete(key)
        except Exception as e:
            print(f"Redis delete error: {e}")

class MultilevelCache:
    def __init__(self, l1_cache: L1Cache, l2_cache: L2Cache):
        self.l1 = l1_cache
        self.l2 = l2_cache
        self.stats = {"l1_hits": 0, "l2_hits": 0, "misses": 0}

    async def get(self, key: str) -> Optional[Any]:
        # L1缓存查找
        value = await self.l1.get(key)
        if value:
            self.stats["l1_hits"] += 1
            return value

        # L2缓存查找
        value = await self.l2.get(key)
        if value:
            self.stats["l2_hits"] += 1
            # 回填L1缓存
            await self.l1.set(key, value)
            return value

        self.stats["misses"] += 1
        return None

    async def set(self, key: str, value: Any, ttl: int = 3600):
        # 同时写入L1和L2
        await asyncio.gather(
            self.l1.set(key, value, ttl),
            self.l2.set(key, value, ttl)
        )

    def get_hit_rate(self) -> float:
        total = sum(self.stats.values())
        if total == 0:
            return 0.0
        hits = self.stats["l1_hits"] + self.stats["l2_hits"]
        return hits / total
```

### 2. 连接池管理

```python
# services/pooling/connection_pool.py
import asyncio
import aiohttp
from typing import Optional, Dict, Any
from contextlib import asynccontextmanager

class ConnectionPool:
    def __init__(self,
                 base_url: str,
                 max_connections: int = 100,
                 min_connections: int = 10,
                 connection_timeout: int = 30):
        self.base_url = base_url
        self.max_connections = max_connections
        self.min_connections = min_connections
        self.connection_timeout = connection_timeout

        self.pool = asyncio.Queue(maxsize=max_connections)
        self.active_connections = 0
        self.pool_lock = asyncio.Lock()

    async def initialize(self):
        """初始化连接池"""
        for _ in range(self.min_connections):
            connection = await self._create_connection()
            await self.pool.put(connection)
            self.active_connections += 1

    @asynccontextmanager
    async def get_connection(self):
        """获取连接"""
        connection = None
        try:
            # 尝试从池中获取连接
            try:
                connection = await asyncio.wait_for(
                    self.pool.get(), timeout=1.0
                )
            except asyncio.TimeoutError:
                # 池中没有可用连接，创建新连接
                async with self.pool_lock:
                    if self.active_connections < self.max_connections:
                        connection = await self._create_connection()
                        self.active_connections += 1
                    else:
                        # 等待可用连接
                        connection = await self.pool.get()

            yield connection

        except Exception as e:
            # 连接出错，移除并创建新连接
            if connection:
                await self._close_connection(connection)
                async with self.pool_lock:
                    self.active_connections -= 1
                    # 异步创建新连接补充池
                    asyncio.create_task(self._补充连接())
            raise e

        finally:
            # 归还连接到池
            if connection and not connection.closed:
                await self.pool.put(connection)

    async def _create_connection(self) -> aiohttp.ClientSession:
        """创建新连接"""
        timeout = aiohttp.ClientTimeout(total=self.connection_timeout)
        connector = aiohttp.TCPConnector(
            limit=0,  # 无限制
            limit_per_host=self.max_connections,
            keepalive_timeout=30,
            enable_cleanup_closed=True
        )

        return aiohttp.ClientSession(
            connector=connector,
            timeout=timeout,
            base_url=self.base_url
        )

    async def _close_connection(self, connection: aiohttp.ClientSession):
        """关闭连接"""
        if not connection.closed:
            await connection.close()

    async def _补充连接(self):
        """补充连接池"""
        async with self.pool_lock:
            if self.active_connections < self.min_connections:
                connection = await self._create_connection()
                await self.pool.put(connection)
                self.active_connections += 1

    async def close_all(self):
        """关闭所有连接"""
        while not self.pool.empty():
            connection = await self.pool.get()
            await self._close_connection(connection)
        self.active_connections = 0

# AI服务连接池
class AIServicePool:
    def __init__(self):
        self.pools = {}
        self.circuit_breakers = {}

    async def add_service(self, service_name: str, base_url: str, **kwargs):
        """添加AI服务"""
        pool = ConnectionPool(base_url, **kwargs)
        await pool.initialize()
        self.pools[service_name] = pool

        # 为每个服务添加熔断器
        self.circuit_breakers[service_name] = CircuitBreaker()

    async def call_service(self, service_name: str, endpoint: str, **kwargs) -> Dict:
        """调用AI服务"""
        if service_name not in self.pools:
            raise ValueError(f"Service {service_name} not found")

        pool = self.pools[service_name]
        breaker = self.circuit_breakers[service_name]

        async with pool.get_connection() as connection:
            async with connection.request(endpoint, **kwargs) as response:
                return await response.json()

    async def close_all(self):
        """关闭所有连接池"""
        for pool in self.pools.values():
            await pool.close_all()
```

## 🚀 部署与运维

### 1. 自动化部署

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

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
        pip install pytest pytest-asyncio pytest-cov

    - name: Run tests
      env:
        DATABASE_URL: postgresql://postgres:test_password@localhost:5432/test
        REDIS_URL: redis://localhost:6379
        OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      run: |
        pytest tests/ -v --cov=services --cov-report=xml

    - name: Upload coverage
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

    - name: Build and push Docker images
      run: |
        # 构建各个服务的镜像
        for service in user-service world-service character-service ai-service; do
          docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-${service}:latest -f services/${service}/Dockerfile .
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-${service}:latest
        done

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
        # 更新镜像版本
        kubectl set image deployment/user-service user-service=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-user-service:latest -n ai-world
        kubectl set image deployment/world-service world-service=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-world-service:latest -n ai-world
        kubectl set image deployment/character-service character-service=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-character-service:latest -n ai-world
        kubectl set image deployment/ai-service ai-service=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-ai-service:latest -n ai-world

        # 等待部署完成
        kubectl rollout status deployment/user-service -n ai-world --timeout=300s
        kubectl rollout status deployment/world-service -n ai-world --timeout=300s
        kubectl rollout status deployment/character-service -n ai-world --timeout=300s
        kubectl rollout status deployment/ai-service -n ai-world --timeout=300s
```

### 2. 监控告警

```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'ai-world-services'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - ai-world
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__

  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

---
# monitoring/alert_rules.yml
groups:
  - name: ai-world-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(ai_world_requests_total{status!~"2.."}[5m]) / rate(ai_world_requests_total[5m]) > 0.05
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.service }}"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(ai_world_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s for {{ $labels.endpoint }}"

      - alert: AIServiceDown
        expr: up{job="ai-world-services", service="ai-service"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "AI service is down"
          description: "AI service has been down for more than 1 minute"

      - alert: DatabaseConnectionsHigh
        expr: pg_stat_activity_count > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High database connections"
          description: "Database has {{ $value }} active connections"
```

## 📊 成本优化

### 1. 资源自动扩缩容

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ai-service-hpa
  namespace: ai-world
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-service
  minReplicas: 4
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: ai_requests_per_second
      target:
        type: AverageValue
        averageValue: "10"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max

---
# k8s/vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: ai-service-vpa
  namespace: ai-world
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-service
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: ai-service
      maxAllowed:
        cpu: 4000m
        memory: 8Gi
      minAllowed:
        cpu: 500m
        memory: 1Gi
```

### 2. 智能调度策略

```python
# services/scheduling/intelligent_scheduler.py
import asyncio
import math
from typing import Dict, List, Tuple
from dataclasses import dataclass

@dataclass
class ResourceRequirement:
    cpu: float
    memory: float
    gpu: bool = False
    storage: float = 0

@dataclass
class NodeInfo:
    id: str
    available_cpu: float
    available_memory: float
    available_gpu: int
    cost_per_hour: float
    region: str

class IntelligentScheduler:
    def __init__(self):
        self.nodes = {}
        self.workload_queue = asyncio.Queue()
        self.cost_budget = 100.0  # 每小时预算

    def add_node(self, node: NodeInfo):
        """添加节点"""
        self.nodes[node.id] = node

    async def schedule_workload(self, workload_id: str,
                              requirements: ResourceRequirement,
                              priority: int = 0) -> str:
        """调度工作负载"""
        # 找到最优节点
        best_node = await self._find_best_node(requirements)

        if not best_node:
            raise Exception("No available node for workload")

        # 检查成本约束
        if best_node.cost_per_hour > self.cost_budget:
            raise Exception("Node cost exceeds budget")

        # 分配工作负载
        await self._allocate_workload(best_node.id, workload_id, requirements)

        return best_node.id

    async def _find_best_node(self, requirements: ResourceRequirement) -> NodeInfo:
        """找到最优节点"""
        suitable_nodes = []

        for node in self.nodes.values():
            if self._can_satisfy_requirements(node, requirements):
                score = self._calculate_node_score(node, requirements)
                suitable_nodes.append((node, score))

        if not suitable_nodes:
            return None

        # 选择得分最高的节点
        suitable_nodes.sort(key=lambda x: x[1], reverse=True)
        return suitable_nodes[0][0]

    def _can_satisfy_requirements(self, node: NodeInfo,
                                requirements: ResourceRequirement) -> bool:
        """检查节点是否满足需求"""
        if node.available_cpu < requirements.cpu:
            return False
        if node.available_memory < requirements.memory:
            return False
        if requirements.gpu and node.available_gpu <= 0:
            return False
        return True

    def _calculate_node_score(self, node: NodeInfo,
                            requirements: ResourceRequirement) -> float:
        """计算节点得分"""
        # 资源利用率得分 (利用率适中得分高)
        cpu_utilization = (node.available_cpu - requirements.cpu) / node.available_cpu
        memory_utilization = (node.available_memory - requirements.memory) / node.available_memory
        utilization_score = 1.0 - abs(cpu_utilization - 0.3) - abs(memory_utilization - 0.3)

        # 成本得分 (成本低得分高)
        max_cost = max(n.cost_per_hour for n in self.nodes.values())
        cost_score = 1.0 - (node.cost_per_hour / max_cost)

        # 地理位置得分 (就近优先)
        # 这里简化为固定值，实际应根据用户位置计算
        geo_score = 0.8 if node.region == "us-east-1" else 0.5

        # 综合得分
        total_score = (
            utilization_score * 0.4 +
            cost_score * 0.4 +
            geo_score * 0.2
        )

        return total_score

    async def _allocate_workload(self, node_id: str, workload_id: str,
                               requirements: ResourceRequirement):
        """分配工作负载到节点"""
        node = self.nodes[node_id]
        node.available_cpu -= requirements.cpu
        node.available_memory -= requirements.memory
        if requirements.gpu:
            node.available_gpu -= 1

        # 这里应该调用实际的调度接口
        print(f"Allocated workload {workload_id} to node {node_id}")

    async def release_workload(self, node_id: str, workload_id: str,
                             requirements: ResourceRequirement):
        """释放工作负载"""
        node = self.nodes[node_id]
        node.available_cpu += requirements.cpu
        node.available_memory += requirements.memory
        if requirements.gpu:
            node.available_gpu += 1

        print(f"Released workload {workload_id} from node {node_id}")
```

---

**文档版本**: v1.0
**最后更新**: 2024-11-10
**维护者**: AI World 开发团队

这份分布式架构设计文档提供了从单机到云原生的完整演进路径，为构建大规模、高可用的AI虚拟世界提供了坚实的技术基础。通过微服务架构、智能调度、自动扩缩容等技术，确保系统能够支持海量用户并发访问。