# AI 世界数据结构与系统设计

## 📋 概述

本文档详细描述了 AI 驱动虚拟世界的核心数据结构、系统架构设计以及数据流模式。基于 Microverse 项目的实践经验，提供了一套可扩展、高性能的数据模型设计方案。

## 🏗️ 系统架构概览

### 1. 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                     前端层 (Frontend Layer)                    │
├─────────────────────────────────────────────────────────────────┤
│  Web UI  │  Mobile App  │  Desktop Client  │  VR Interface     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API 网关层 (API Gateway)                    │
├─────────────────────────────────────────────────────────────────┤
│  认证授权  │  限流控制  │  负载均衡  │  请求路由               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   业务服务层 (Business Layer)                   │
├─────────────────────────────────────────────────────────────────┤
│ AI服务    │  角色管理  │  对话系统  │  任务系统  │  世界状态     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   数据访问层 (Data Access Layer)                 │
├─────────────────────────────────────────────────────────────────┤
│  缓存层  │  消息队列  │  搜索引擎  │  文件存储                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   数据存储层 (Data Storage Layer)                │
├─────────────────────────────────────────────────────────────────┤
│ 关系数据库  │  文档数据库  │  时序数据库  │  对象存储             │
└─────────────────────────────────────────────────────────────────┘
```

### 2. 微服务架构

#### 核心服务模块

```yaml
# docker-compose.services.yml
services:
  # API 网关
  api-gateway:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - auth-service
      - ai-service
      - character-service

  # 认证服务
  auth-service:
    build: ./services/auth
    environment:
      - DATABASE_URL=postgresql://user:pass@auth-db:5432/auth
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - auth-db

  # AI 服务
  ai-service:
    build: ./services/ai
    environment:
      - DATABASE_URL=postgresql://user:pass@ai-db:5432/ai
      - REDIS_URL=redis://redis:6379
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    depends_on:
      - ai-db
      - redis
      - rabbitmq

  # 角色管理服务
  character-service:
    build: ./services/character
    environment:
      - DATABASE_URL=postgresql://user:pass@character-db:5432/character
      - ELASTICSEARCH_URL=http://elasticsearch:9200
    depends_on:
      - character-db
      - elasticsearch

  # 对话系统服务
  conversation-service:
    build: ./services/conversation
    environment:
      - DATABASE_URL=postgresql://user:pass@conversation-db:5432/conversation
      - REDIS_URL=redis://redis:6379
    depends_on:
      - conversation-db
      - redis

  # 任务系统服务
  task-service:
    build: ./services/task
    environment:
      - DATABASE_URL=postgresql://user:pass@task-db:5432/task
      - REDIS_URL=redis://redis:6379
    depends_on:
      - task-db
      - redis
```

## 📊 核心数据结构设计

### 1. 角色数据模型

#### Character 实体
```sql
-- 角色基础信息表
CREATE TABLE characters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(500),
    description TEXT,

    -- 角色属性
    position VARCHAR(100) NOT NULL,
    personality TEXT NOT NULL,
    speaking_style TEXT NOT NULL,
    work_duties TEXT,
    work_habits TEXT,

    -- 状态信息
    current_location POINT,
    current_state VARCHAR(50) DEFAULT 'idle',
    health_status INTEGER DEFAULT 100,
    energy_level INTEGER DEFAULT 100,
    mood_score INTEGER DEFAULT 50,

    -- AI 配置
    ai_model_config JSONB NOT NULL DEFAULT '{}',
    ai_temperature DECIMAL(3,2) DEFAULT 0.7,
    ai_max_tokens INTEGER DEFAULT 2048,

    -- 元数据
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,

    -- 索引
    CONSTRAINT characters_name_unique UNIQUE (name),
    CONSTRAINT characters_mood_score CHECK (mood_score >= 0 AND mood_score <= 100),
    CONSTRAINT characters_energy_level CHECK (energy_level >= 0 AND energy_level <= 100)
);

-- 角色关系表
CREATE TABLE character_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_a_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    character_b_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,

    relationship_type VARCHAR(50) NOT NULL, -- friend, colleague, rival, etc.
    relationship_strength INTEGER NOT NULL CHECK (relationship_strength >= -10 AND relationship_strength <= 10),
    trust_level INTEGER DEFAULT 0 CHECK (trust_level >= -10 AND trust_level <= 10),

    -- 关系历史
    interaction_count INTEGER DEFAULT 0,
    last_interaction_at TIMESTAMP WITH TIME ZONE,
    relationship_history JSONB DEFAULT '[]',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(character_a_id, character_b_id)
);

-- 角色技能表
CREATE TABLE character_skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,

    skill_name VARCHAR(100) NOT NULL,
    skill_level INTEGER NOT NULL CHECK (skill_level >= 0 AND skill_level <= 100),
    skill_category VARCHAR(50) NOT NULL, -- technical, social, creative, etc.
    experience_points INTEGER DEFAULT 0,

    -- 技能使用统计
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(character_id, skill_name)
);
```

#### 角色状态模型
```json
{
  "character_id": "uuid",
  "basic_info": {
    "name": "Alice",
    "display_name": "Alice Johnson",
    "position": "前端工程师",
    "avatar_url": "https://example.com/avatars/alice.png"
  },
  "personality": {
    "traits": ["creative", "detail-oriented", "collaborative"],
    "values": ["innovation", "quality", "teamwork"],
    "motivations": ["learning", "recognition", "impact"]
  },
  "current_state": {
    "location": {"x": 100.5, "y": 200.3, "z": 0},
    "status": "working",
    "mood": "focused",
    "energy": 85,
    "health": 95
  },
  "social_context": {
    "nearby_characters": ["bob", "charlie"],
    "current_conversation": null,
    "recent_interactions": [
      {
        "character_id": "bob",
        "type": "conversation",
        "timestamp": "2024-01-01T10:30:00Z",
        "sentiment": 0.7
      }
    ]
  },
  "ai_config": {
    "model": "gpt-4",
    "temperature": 0.7,
    "max_tokens": 2048,
    "system_prompt": "你是Alice，一位有创造力的前端工程师..."
  }
}
```

### 2. 记忆系统数据模型

#### Memory 实体
```sql
-- 记忆表
CREATE TABLE memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,

    -- 记忆内容
    content TEXT NOT NULL,
    memory_type VARCHAR(50) NOT NULL, -- personal, interaction, task, emotion, event
    importance INTEGER NOT NULL CHECK (importance >= 1 AND importance <= 10),

    -- 情感标记
    emotion_type VARCHAR(50), -- joy, sadness, anger, fear, surprise, disgust
    emotion_intensity INTEGER CHECK (emotion_intensity >= 0 AND emotion_intensity <= 10),

    -- 关联信息
    related_character_ids UUID[] DEFAULT '{}',
    related_location POINT,
    related_objects JSONB DEFAULT '{}',

    -- 记忆特征
    tags TEXT[] DEFAULT '{}',
    keywords TEXT[] DEFAULT '{}',
    summary TEXT, -- AI 生成的记忆摘要

    -- 访问模式
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    forgetting_factor DECIMAL(3,2) DEFAULT 1.0, -- 遗忘因子

    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    memory_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- 向量化存储 (用于语义搜索)
    embedding VECTOR(1536),

    -- 索引
    INDEX idx_memories_character_importance (character_id, importance DESC),
    INDEX idx_memories_type_timestamp (memory_type, memory_timestamp DESC),
    INDEX idx_memories_embedding USING ivfflat (embedding vector_cosine_ops)
);

-- 记忆关联表 (记忆网络)
CREATE TABLE memory_associations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_memory_id UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
    target_memory_id UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,

    association_type VARCHAR(50) NOT NULL, -- causal, temporal, semantic, emotional
    association_strength DECIMAL(3,2) NOT NULL CHECK (association_strength >= 0 AND association_strength <= 1),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(source_memory_id, target_memory_id, association_type)
);

-- 记忆反思表 (AI 对记忆的反思和总结)
CREATE TABLE memory_reflections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,

    -- 反思内容
    reflection_type VARCHAR(50) NOT NULL, -- daily, weekly, event_based
    reflection_content TEXT NOT NULL,
    reflected_memories UUID[] NOT NULL,

    -- 反思结果
    insights_generated JSONB DEFAULT '[]',
    behavior_changes JSONB DEFAULT '{}',
    emotional_impact DECIMAL(3,2),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 记忆数据结构
```json
{
  "memory_id": "uuid",
  "character_id": "uuid",
  "content": "和Bob讨论了新项目的设计方案，他对我的想法很赞同",

  "metadata": {
    "type": "interaction",
    "importance": 7,
    "emotion": {
      "type": "satisfaction",
      "intensity": 8
    },
    "timestamp": "2024-01-01T14:30:00Z",
    "location": {"x": 150, "y": 200, "room": "office"},
    "participants": ["alice", "bob"],
    "tags": ["work", "collaboration", "design", "positive"],
    "keywords": ["项目", "设计", "讨论", "赞同"]
  },

  "associations": [
    {
      "memory_id": "uuid",
      "type": "causal",
      "strength": 0.8,
      "description": "这次讨论导致了任务分配"
    }
  ],

  "access_pattern": {
    "access_count": 3,
    "last_accessed": "2024-01-02T09:15:00Z",
    "forgetting_factor": 0.95
  },

  "ai_generated": {
    "summary": "与Bob进行了愉快的工作讨论",
    "insights": ["团队合作很重要", "我的设计能力得到了认可"],
    "embedding": [0.1, 0.2, 0.3, ...] // 1536维向量
  }
}
```

### 3. 任务系统数据模型

#### Task 实体
```sql
-- 任务表
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,

    -- 任务属性
    task_type VARCHAR(50) NOT NULL, -- work, social, personal, emergency
    priority INTEGER NOT NULL CHECK (priority >= 1 AND priority <= 10),
    difficulty_level INTEGER CHECK (difficulty_level >= 1 AND difficulty_level <= 10),

    -- 任务状态
    status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, failed, cancelled
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),

    -- 分配信息
    assigned_character_id UUID REFERENCES characters(id) ON DELETE SET NULL,
    created_by_character_id UUID REFERENCES characters(id) ON DELETE SET NULL,

    -- 时间管理
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    estimated_duration INTERVAL,

    -- 任务依赖
    prerequisites UUID[] DEFAULT '{}',
    dependents UUID[] DEFAULT '{}',

    -- 任务奖励
    experience_reward INTEGER DEFAULT 0,
    relationship_impacts JSONB DEFAULT '{}',

    -- 任务条件
    completion_conditions JSONB DEFAULT '{}',
    failure_conditions JSONB DEFAULT '{}',

    -- AI 相关
    ai_generated BOOLEAN DEFAULT false,
    generation_prompt TEXT,
    completion_ai_review BOOLEAN DEFAULT true
);

-- 任务步骤表
CREATE TABLE task_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,

    step_order INTEGER NOT NULL,
    step_title VARCHAR(200) NOT NULL,
    step_description TEXT,

    step_type VARCHAR(50) NOT NULL, -- action, dialogue, movement, waiting
    step_status VARCHAR(50) DEFAULT 'pending',

    -- 步骤参数
    step_parameters JSONB DEFAULT '{}',
    required_objects JSONB DEFAULT '{}',
    target_location POINT,

    -- 时间信息
    estimated_duration INTERVAL,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(task_id, step_order)
);

-- 任务执行历史表
CREATE TABLE task_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,

    execution_attempt INTEGER NOT NULL,
    execution_status VARCHAR(50) NOT NULL,

    -- 执行结果
    execution_result JSONB DEFAULT '{}',
    lessons_learned TEXT,

    -- 时间记录
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    actual_duration INTERVAL,

    -- AI 分析
    ai_success_probability DECIMAL(3,2),
    ai_failure_reasons JSONB DEFAULT '[]',
    ai_improvement_suggestions JSONB DEFAULT '[]'
);
```

### 4. 对话系统数据模型

#### Conversation 实体
```sql
-- 对话会话表
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 对话参与者
    participant_ids UUID[] NOT NULL,
    conversation_type VARCHAR(50) NOT NULL, -- one_on_one, group, meeting

    -- 对话上下文
    topic VARCHAR(200),
    context JSONB DEFAULT '{}',

    -- 对话状态
    status VARCHAR(50) DEFAULT 'active', -- active, paused, ended
    current_speaker_id UUID REFERENCES characters(id) ON DELETE SET NULL,

    -- 时间信息
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- 对话统计
    message_count INTEGER DEFAULT 0,
    participant_moods JSONB DEFAULT '{}',

    -- AI 相关
    ai_moderated BOOLEAN DEFAULT false,
    ai_summary TEXT,
    ai_topics_extracted JSONB DEFAULT '[]'
);

-- 对话消息表
CREATE TABLE conversation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,

    -- 消息内容
    sender_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text', -- text, emoji, action, system

    -- 消息元数据
    tone VARCHAR(50), -- formal, casual, angry, happy, etc.
    intent VARCHAR(100), -- greeting, question, statement, farewell, etc.
    emotional_sentiment DECIMAL(3,2) CHECK (emotional_sentiment >= -1 AND emotional_sentiment <= 1),

    -- 消息状态
    delivery_status VARCHAR(50) DEFAULT 'sent', -- sent, delivered, read, failed
    edited_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,

    -- AI 分析
    ai_generated BOOLEAN DEFAULT false,
    ai_confidence DECIMAL(3,2),
    ai_topics JSONB DEFAULT '[]',
    ai_entities JSONB DEFAULT '[]',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 对话上下文缓存表 (Redis 兼容)
CREATE TABLE conversation_contexts (
    conversation_id UUID PRIMARY KEY,

    -- 当前对话状态
    current_topic VARCHAR(200),
    recent_topics JSONB DEFAULT '[]',
    participant_states JSONB DEFAULT '{}',

    -- 上下文向量
    context_embedding VECTOR(1536),

    -- 缓存控制
    expires_at TIMESTAMP WITH TIME ZONE,
    version INTEGER DEFAULT 1,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🔄 数据流设计

### 1. AI 决策数据流

```
角色状态查询
    ↓
记忆检索 (按重要性排序)
    ↓
上下文构建 (环境+关系+任务)
    ↓
Prompt 组装
    ↓
AI 模型推理
    ↓
决策解析
    ↓
动作执行
    ↓
状态更新 → 新记忆生成
```

#### AI 决策服务接口
```typescript
interface AIDecisionService {
  // 获取角色决策
  getCharacterDecision(request: DecisionRequest): Promise<DecisionResponse>;

  // 执行角色动作
  executeAction(request: ActionRequest): Promise<ActionResult>;

  // 更新角色状态
  updateCharacterState(request: StateUpdateRequest): Promise<void>;
}

interface DecisionRequest {
  character_id: string;
  current_context: {
    location: Point;
    nearby_characters: string[];
    current_time: Date;
    environment_state: Record<string, any>;
  };
  decision_type: 'movement' | 'dialogue' | 'task' | 'social';
}

interface DecisionResponse {
  decision_id: string;
  chosen_action: {
    type: string;
    parameters: Record<string, any>;
    confidence: number;
    reasoning: string;
  };
  alternatives: Action[];
  execution_plan: ExecutionStep[];
}
```

### 2. 记忆管理数据流

```
事件触发
    ↓
记忆重要性评估
    ↓
记忆格式化
    ↓
向量化存储
    ↓
关联网络更新
    ↓
遗忘机制处理
    ↓
长期存储归档
```

#### 记忆管理服务
```typescript
interface MemoryService {
  // 创建记忆
  createMemory(request: CreateMemoryRequest): Promise<Memory>;

  // 检索记忆
  retrieveMemories(query: MemoryQuery): Promise<Memory[]>;

  // 更新记忆
  updateMemory(request: UpdateMemoryRequest): Promise<Memory>;

  // 语义搜索记忆
  searchMemoriesByEmbedding(query: string, character_id: string): Promise<Memory[]>;

  // 记忆反思
  reflectOnMemories(character_id: string, reflection_type: string): Promise<Reflection>;
}

interface CreateMemoryRequest {
  character_id: string;
  content: string;
  memory_type: MemoryType;
  importance: number;
  emotion?: EmotionData;
  related_entities?: RelatedEntity[];
  timestamp?: Date;
}

interface MemoryQuery {
  character_id: string;
  memory_types?: MemoryType[];
  importance_range?: [number, number];
  time_range?: [Date, Date];
  keywords?: string[];
  limit?: number;
  offset?: number;
}
```

### 3. 任务执行数据流

```
任务生成
    ↓
任务分配
    ↓
执行计划制定
    ↓
步骤执行
    ↓
进度跟踪
    ↓
完成验证
    ↓
奖励发放
    ↓
经验更新
```

## 🔧 性能优化策略

### 1. 数据库优化

#### 索引策略
```sql
-- 角色相关索引
CREATE INDEX CONCURRENTLY idx_characters_location ON characters USING GIST (current_location);
CREATE INDEX CONCURRENTLY idx_characters_state ON characters (current_state, updated_at);
CREATE INDEX CONCURRENTLY idx_characters_active ON characters (is_active) WHERE is_active = true;

-- 记忆相关索引
CREATE INDEX CONCURRENTLY idx_memories_character_type ON characters (character_id, memory_type, importance DESC);
CREATE INDEX CONCURRENTLY idx_memories_timestamp ON memories (memory_timestamp DESC);
CREATE INDEX CONCURRENTLY idx_memories_embedding ON memories USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- 任务相关索引
CREATE INDEX CONCURRENTLY idx_tasks_assignee_priority ON tasks (assigned_character_id, priority DESC, status);
CREATE INDEX CONCURRENTLY idx_tasks_due_date ON tasks (due_date) WHERE due_date IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_tasks_dependencies ON tasks USING GIN (prerequisites, dependents);

-- 对话相关索引
CREATE INDEX CONCURRENTLY idx_conversations_participants ON conversations USING GIN (participant_ids);
CREATE INDEX CONCURRENTLY idx_conversation_messages_conversation ON conversation_messages (conversation_id, created_at);
CREATE INDEX CONCURRENTLY idx_conversation_messages_sender ON conversation_messages (sender_id, created_at DESC);
```

#### 分区策略
```sql
-- 按时间分区记忆表
CREATE TABLE memories_partitioned (
    LIKE memories INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- 创建月度分区
CREATE TABLE memories_2024_01 PARTITION OF memories_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE memories_2024_02 PARTITION OF memories_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- 按时间分区对话消息表
CREATE TABLE conversation_messages_partitioned (
    LIKE conversation_messages INCLUDING ALL
) PARTITION BY RANGE (created_at);

CREATE TABLE messages_2024_01 PARTITION OF conversation_messages_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### 2. 缓存策略

#### Redis 缓存结构
```typescript
interface CacheKeys {
  // 角色状态缓存 (TTL: 5分钟)
  character_state: `character:${string}:state`;

  // 角色记忆缓存 (TTL: 1小时)
  character_memories: `character:${string}:memories:${number}`; // importance level

  // 对话上下文缓存 (TTL: 30分钟)
  conversation_context: `conversation:${string}:context`;

  // 任务列表缓存 (TTL: 10分钟)
  character_tasks: `character:${string}:tasks:${string}`; // status

  // AI 模型响应缓存 (TTL: 24小时)
  ai_response: `ai:${string}:${string}`; // model:prompt_hash
}

interface CacheService {
  // 获取角色状态
  getCharacterState(character_id: string): Promise<CharacterState | null>;

  // 缓存角色记忆
  cacheCharacterMemories(character_id: string, memories: Memory[]): Promise<void>;

  // 缓存对话上下文
  cacheConversationContext(conversation_id: string, context: ConversationContext): Promise<void>;

  // 缓存 AI 响应
  cacheAIResponse(model: string, prompt_hash: string, response: string): Promise<void>;
}
```

### 3. 查询优化

#### 批量查询接口
```typescript
interface BatchQueryService {
  // 批量获取角色状态
  batchGetCharacterStates(character_ids: string[]): Promise<Map<string, CharacterState>>;

  // 批量获取角色记忆
  batchGetCharacterMemories(queries: CharacterMemoryQuery[]): Promise<Map<string, Memory[]>>;

  // 批量获取任务信息
  batchGetTasks(task_ids: string[]): Promise<Map<string, Task>>;

  // 批量获取对话历史
  batchGetConversationHistory(conversation_ids: string[]): Promise<Map<string, ConversationMessage[]>>;
}

interface CharacterMemoryQuery {
  character_id: string;
  memory_types?: MemoryType[];
  limit?: number;
  importance_threshold?: number;
}
```

## 📈 扩展性设计

### 1. 水平扩展

#### 数据库分片策略
```sql
-- 按角色ID分片
CREATE TABLE characters_shard_1 (
    LIKE characters INCLUDING ALL
);
CREATE TABLE characters_shard_2 (
    LIKE characters INCLUDING ALL
);

-- 分片路由函数
CREATE OR REPLACE FUNCTION get_character_shard(character_id UUID)
RETURNS TEXT AS $$
BEGIN
    RETURN 'characters_shard_' || (mod(abs(hashtext(character_id::text)), 2) + 1);
END;
$$ LANGUAGE plpgsql;
```

#### 服务扩展配置
```yaml
# Kubernetes 水平扩展配置
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ai-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-service
  minReplicas: 2
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
```

### 2. 垂直扩展

#### 资源配置优化
```yaml
# 高性能实例配置
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: ai-service
    resources:
      requests:
        cpu: "2"
        memory: "8Gi"
        nvidia.com/gpu: 1
      limits:
        cpu: "4"
        memory: "16Gi"
        nvidia.com/gpu: 2
    env:
    - name: OMP_NUM_THREADS
      value: "4"
    - name: CUDA_VISIBLE_DEVICES
      value: "0,1"
```

## 🔒 数据安全设计

### 1. 数据加密

```sql
-- 敏感数据加密存储
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 加密个人信息
CREATE TABLE character_private_data (
    character_id UUID PRIMARY KEY REFERENCES characters(id) ON DELETE CASCADE,
    encrypted_personal_info BYTEA, -- 加密的个人信息
    encryption_key_id VARCHAR(100),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 加密函数
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(data TEXT, key TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(data, key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2. 访问控制

```typescript
interface AccessControlService {
  // 检查数据访问权限
  checkDataAccess(user_id: string, resource_type: string, resource_id: string): Promise<boolean>;

  // 获取可访问的角色列表
  getAccessibleCharacters(user_id: string): Promise<string[]>;

  // 检查操作权限
  checkOperationPermission(user_id: string, operation: string, target: string): Promise<boolean>;
}

enum Permission {
  READ_CHARACTER = 'character:read',
  WRITE_CHARACTER = 'character:write',
  READ_MEMORIES = 'memories:read',
  WRITE_MEMORIES = 'memories:write',
  MANAGE_TASKS = 'tasks:manage',
  VIEW_CONVERSATIONS = 'conversations:view';
}
```

---

_文档版本: v1.0_
_最后更新: 2024-11-10_
_维护者: AI开发团队_

这份数据结构与系统设计文档为AI世界项目提供了完整的数据架构基础，涵盖了从概念设计到具体实现的所有关键环节，确保系统的可扩展性、性能和安全性。