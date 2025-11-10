# 记忆系统架构文档

## 📋 概述

Microverse 项目采用多层次的记忆存储系统，通过角色元数据(`character_data`)、对话历史(`ChatHistory`)和持久化存档(`GameSaveManager`)共同构建了完整的角色记忆和历史记录体系。

## 🏗️ 记忆系统架构

### 1. 核心组件

```
记忆系统
├── MemoryManager.gd          # 记忆管理器
├── ChatHistory.gd           # 对话历史管理
├── GameSaveManager.gd       # 持久化存档
└── character_data (元数据)   # 角色数据载体
```

### 2. 数据存储层次

```
运行时内存 (Runtime)
├── Node.set_meta("character_data")  # 角色元数据
│   ├── memories[]                   # 记忆数组
│   ├── tasks[]                      # 任务列表
│   ├── relations{}                  # 情感关系
│   └── last_task_refresh            # 任务刷新时间
│
└── ChatHistory节点                  # 对话历史节点
    └── history{}                    # 按参与者分组的对话记录

持久化存储 (Persistent Storage)
├── user://chat_history/             # 对话历史文件
│   └── [character]_history.json     # 每个角色的对话历史
│
└── user://saves/                    # 游戏存档文件
    └── [save_name].json             # 完整游戏状态存档
```

## 💾 记忆存储详细机制

### 1. 角色记忆存储 (MemoryManager.gd)

#### 1.1 记忆数据结构

```json
{
  "content": "记忆内容文本",
  "timestamp": "2024-01-01 14:30",
  "type": 0, // MemoryType枚举值
  "importance": 3, // 重要性等级 (1-10)
  "created_at": 1704110400.0 // Unix时间戳
}
```

#### 1.2 记忆类型分类

```gdscript
enum MemoryType {
    PERSONAL,      // 个人记忆 - 角色的个人想法和感受
    INTERACTION,   // 互动记忆 - 与其他角色的互动记录
    TASK,          // 任务记忆 - 工作任务相关记录
    EMOTION,       // 情感记忆 - 情感体验和情绪变化
    EVENT          // 事件记忆 - 重要事件记录
}
```

#### 1.3 重要性等级

```gdscript
enum MemoryImportance {
    LOW = 1,        // 低重要性 - 日常琐事
    NORMAL = 3,     // 普通重要性 - 常规活动
    HIGH = 5,       // 高重要性 - 重要事件
    CRITICAL = 10   // 关键重要性 - 重大转折点
}
```

#### 1.4 存储实现

**添加记忆** ([`MemoryManager.gd:32-62`](script/ai/memory/MemoryManager.gd#L32-L62)):

```gdscript
func add_memory(character: Node, memory_content: String, memory_type: MemoryType, importance: MemoryImportance):
    # 1. 创建记忆对象
    var memory_obj = {
        "content": memory_content,
        "timestamp": 时间字符串,
        "type": memory_type,
        "importance": importance,
        "created_at": Unix时间戳
    }

    # 2. 获取角色元数据
    var character_data = character.get_meta("character_data", {})
    if not character_data.has("memories"):
        character_data["memories"] = []

    # 3. 添加记忆并保存
    character_data["memories"].append(memory_obj)
    character.set_meta("character_data", character_data)

    # 4. 清理旧记忆
    _cleanup_old_memories(character)
```

**记忆清理机制** ([`MemoryManager.gd:130-158`](script/ai/memory/MemoryManager.gd#L130-L158)):

```gdscript
func _cleanup_old_memories(character: Node, max_memories: int = 50):
    # 按重要性和时间排序
    # 优先保留：高重要性 + 最新记忆
    # 丢弃：低重要性 + 旧记忆
```

### 2. 对话历史存储 (ChatHistory.gd)

#### 2.1 对话数据结构

```json
{
  "message": "对话消息内容",
  "timestamp": 1704110400.0,
  "participants": ["角色A", "角色B"]
}
```

#### 2.2 存储组织结构

```gdscript
# 按对话参与者分组存储
var history = {
    "角色A": [
        {
            "message": "角色A说：...",
            "timestamp": 1704110400.0,
            "participants": ["角色A", "角色B"]
        },
        {
            "message": "角色B说：...",
            "timestamp": 1704110460.0,
            "participants": ["角色A", "角色B"]
        }
    ]
}
```

#### 2.3 文件存储机制

**存储路径** ([`ChatHistory.gd:144-147`](script/ChatHistory.gd#L144-L147)):

```gdscript
func get_history_file_path() -> String:
    var node_name = get_parent().name if get_parent() else "default"
    return "user://chat_history/" + node_name + "_history.json"
```

**持久化实现** ([`ChatHistory.gd:124-142`](script/ChatHistory.gd#L124-L142)):

```gdscript
# 保存到文件
func save_history():
    var json_string = JSON.stringify(history)
    file.store_string(json_string)

# 从文件加载
func load_history():
    var json_string = file.get_as_text()
    history = JSON.parse_string(json_string)
```

### 3. 角色数据集成 (character_data)

#### 3.1 数据结构概览

```json
{
  "memories": [
    // 记忆数组，由MemoryManager管理
  ],
  "tasks": [
    {
      "description": "任务描述",
      "priority": 7,
      "created_at": 1704110400.0,
      "completed": false
    }
  ],
  "relations": {
    "其他角色名": {
      "type": "friendship", // 关系类型
      "strength": 8.0 // 关系强度 (-10 到 +10)
    }
  },
  "last_task_refresh": 1704110400.0,
  "metadata": {
    // 其他元数据...
  }
}
```

#### 3.2 元数据访问模式

**写入模式**:

```gdscript
var character_data = character.get_meta("character_data", {})
character_data["memories"] = new_memories
character.set_meta("character_data", character_data)
```

**读取模式**:

```gdscript
var character_data = character.get_meta("character_data", {})
var memories = character_data.get("memories", [])
```

### 4. 持久化存档 (GameSaveManager.gd)

#### 4.1 存档数据结构

```json
{
  "version": "1.0",
  "timestamp": 1704110400.0,
  "scene_name": "Office",
  "characters": [
    {
      "name": "角色名",
      "position": {"x": 100.0, "y": 200.0},
      "character_data": {
        // 完整的character_data内容
        "memories": [...],
        "tasks": [...],
        "relations": {...}
      }
    }
  ],
  "rooms": {},
  "global_state": {}
}
```

#### 4.2 数据收集机制

**角色数据收集** ([`GameSaveManager.gd:120-170`](script/GameSaveManager.gd#L120-L170)):

```gdscript
func collect_character_data(character: Node) -> Dictionary:
    # 1. 基本状态数据
    # 2. AI状态数据
    # 3. 性格数据
    # 4. character_data元数据
```

## 🔄 记忆流动机制

### 1. 记忆生命周期

```
1. 事件发生 → 2. 生成记忆 → 3. 存储到内存 → 4. 影响AI决策
                ↓
        5. 定期清理 → 6. 持久化存档 → 7. 游戏重启后恢复
```

### 2. 记忆使用场景

#### 2.1 AI 决策 ([`AIAgent.gd:288`](script/ai/AIAgent.gd#L288))

```gdscript
# 将记忆作为AI prompt的一部分
status_info += MemoryManager.get_formatted_memories_for_prompt(target_character)
```

#### 2.2 对话决策 ([`AIAgent.gd:618-654`](script/ai/AIAgent.gd#L618-L654))

```gdscript
# 获取对话历史影响聊天决策
var chat_history = history_node.get_recent_conversation_with(partner.name, 10)
```

#### 2.3 情感关系计算

```gdscript
# 基于互动记忆更新角色关系
var relations = character_data.get("relations", {})
```

## 📊 性能优化机制

### 1. 记忆数量限制

- **最多 50 条记忆** ([`MemoryManager.gd:130`](script/ai/memory/MemoryManager.gd#L130))
- **按重要性过滤** ([`MemoryManager.gd:83-87`](script/ai/memory/MemoryManager.gd#L83-L87))
- **时间范围过滤** ([`MemoryManager.gd:102-113`](script/ai/memory/MemoryManager.gd#L102-L113))

### 2. 按需加载

- **分页检索** ([`MemoryManager.gd:91-98`](script/ai/memory/MemoryManager.gd#L91-L98))
- **关键词搜索** ([`MemoryManager.gd:116-127`](script/ai/memory/MemoryManager.gd#L116-L127))
- **最近记忆优先** ([`ChatHistory.gd:75-90`](script/ChatHistory.gd#L75-L90))

### 3. 文件 I/O 优化

- **JSON 格式存储** - 轻量级、易解析
- **按角色分文件** - 减少单文件大小
- **增量保存** - 只在变更时写入

## 🛠️ 开发者接口

### 1. MemoryManager API

```gdscript
# 添加记忆
MemoryManager.add_memory(character, "内容", type, importance)

# 获取记忆
var memories = MemoryManager.get_character_memories(character)

# 格式化记忆用于AI
var formatted = MemoryManager.get_formatted_memories_for_prompt(character, max_count)

# 搜索记忆
var results = MemoryManager.search_memories(character, ["关键词"])

# 获取最近记忆
var recent = MemoryManager.get_recent_memories(character, hours)
```

### 2. ChatHistory API

```gdscript
# 添加消息
chat_history.add_message(speaker_name, message_content)

# 获取对话历史
var history = chat_history.get_history_by_participant(participant_name)

# 获取最近对话
var recent = chat_history.get_recent_conversation_with(participant_name, max_messages)

# 获取完整历史
var full_history = chat_history.get_formatted_history()
```

### 3. 数据持久化

```gdscript
# 保存游戏
GameSaveManager.save_game("存档名")

# 加载游戏
GameSaveManager.load_game("存档名")

# 手动收集数据
var data = GameSaveManager.collect_game_data()
```

## 📈 未来扩展建议

### 1. 记忆压缩算法

- **抽象化处理** - 将相似记忆合并为概念
- **重要性衰减** - 记忆重要性随时间递减
- **情感关联** - 基于情感强度建立记忆网络

### 2. 全局事件系统

- **世界事件** - 影响所有角色的重大事件
- **历史趋势** - 长期行为模式分析
- **因果链条** - 事件间的因果关系追踪

### 3. 性能优化

- **缓存机制** - 频繁访问的记忆缓存
- **异步加载** - 大量记忆的异步处理
- **数据库存储** - 替代 JSON 文件存储

---

_文档版本: v1.0_
_最后更新: 2024-11-10_
_维护者: AI 开发团队_
