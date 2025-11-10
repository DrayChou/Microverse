# AI Prompt 构建与用户管理系统文档

## 📋 概述

本文档详细描述了 Microverse 项目中 AI 调用的 prompt 构建机制、用户基础信息管理系统以及相关的配置管理体系。整个系统通过模块化设计实现了灵活的角色 AI 配置、动态 prompt 构建和多服务商 API 支持。

## 🏗️ 系统架构概览

```
AI Prompt构建系统
├── 用户基础信息管理
│   ├── CharacterPersonality.gd     # 角色人设配置
│   ├── BackgroundStoryManager.gd   # 背景故事管理
│   └── MemoryManager.gd           # 记忆管理系统
│
├── Prompt构建引擎
│   ├── ConversationManager.gd     # 对话prompt构建
│   ├── AIAgent.gd                 # AI决策prompt构建
│   └── DialogManager.gd           # 对话管理器
│
├── API配置与调用
│   ├── APIManager.gd              # API调用管理器
│   ├── APIConfig.gd               # API配置管理
│   └── SettingsManager.gd         # 设置管理器
│
└── 配置数据源
    ├── config/content/            # YAML配置文件
    └── user://settings.cfg        # 用户设置文件
```

## 👤 用户基础信息管理系统

### 1. 角色人设配置 (CharacterPersonality.gd)

#### 1.1 数据结构

每个角色的完整人设配置包含以下字段：

```json
{
  "角色名": {
    "position": "职位名称",
    "personality": "性格描述",
    "speaking_style": "说话风格",
    "work_duties": "工作职责",
    "work_habits": "工作习惯"
  }
}
```

#### 1.2 具体角色配置示例

**Stephen (老板)**:

```json
{
  "position": "SleepySheep公司老板",
  "personality": "奥斯卡级虚伪表演家，职场PUA持证上岗选手，把'奋斗者文化'刻进DNA的剥削型人格",
  "speaking_style": "张嘴就是'期权池已备好'、'明年就敲钟'，把996包装成'青年增值计划'",
  "work_duties": "每周发布新的'三年愿景'，主持'福报宣讲会'，给投资人演示'员工自愿加班'的监控录像",
  "work_habits": "下班时间必在公司群发'深夜奋斗者照片'，定期查看员工电脑监控"
}
```

**Alice (前端工程师)**:

```json
{
  "position": "SleepySheep公司的前端工程师、UI设计师",
  "personality": "设计界的带刺玫瑰，表面高冷实则CPU超频怼人，对不合理需求有过敏性休克反应",
  "speaking_style": "开口就是'这需求的视觉层级比老板的发际线还混乱'，把996称为'像素过劳死计划'",
  "work_duties": "负责产品界面设计，用户体验优化，品牌视觉设计，前端代码实现",
  "work_habits": "办公桌贴满'拒绝福报，从你做起'的像素风贴纸，遇到无理需求就打开劳动法PDF假装查资料"
}
```

#### 1.3 API 接口

```gdscript
# 获取角色人设
static func get_personality(character_name: String) -> Dictionary

# 如果角色不存在，返回默认配置
{
  "personality": "普通的办公室职员",
  "speaking_style": "正常的交谈方式"
}
```

### 2. 背景故事管理 (BackgroundStoryManager.gd)

#### 2.1 支持的场景背景

- **Office**: CountSheep 游戏公司
- **School**: 阳光学院
- **Jail**: 新希望监狱

#### 2.2 背景信息结构

```json
{
  "company_name": "机构名称",
  "company_description": "详细描述",
  "environment_description": "环境描述",
  "time_period": "时间背景",
  "cultural_context": "文化背景",
  "economic_situation": "经济状况",
  "social_rules": ["社会规则1", "社会规则2"]
}
```

#### 2.3 Prompt 生成接口

```gdscript
# 生成完整的背景和规则prompt
static func generate_background_prompt() -> String
```

生成的 prompt 格式：

```
## 故事背景
[背景描述...]

## 社会规则
1. [规则1]
2. [规则2]
...
```

### 3. 记忆系统 (MemoryManager.gd)

记忆系统为 prompt 提供角色历史信息，详见[记忆系统架构文档](memory-system-architecture.md)。

## 🔧 Prompt 构建引擎

### 1. 对话 Prompt 构建 (ConversationManager.gd)

#### 1.1 完整 Prompt 结构

对话 prompt 按以下顺序构建：

```
1. 角色基础信息
   "你是一个员工，名字是[角色名]。你的职位是：[职位]。你的性格是：[性格]。你的说话风格是：[风格]。"

2. 故事背景和社会规则
   [BackgroundStoryManager.generate_background_prompt()]

3. 公司基本信息
   [get_company_basic_info()]

4. 员工名单信息
   [get_company_employees_info()]

5. 说话者状态信息（包含记忆）
   [get_character_status_info() - 包含记忆、情感关系、财务状况等]

6. 当前任务信息
   [get_character_tasks()]

7. 听众基本信息
   "你正在与[听众名]交谈。[听众名]的职位是：[职位]。[听众名]的性格是：[性格]。"

8. 对话历史记录
   "你们之前的对话记录：\n[最近5条对话]"

9. 对话指导原则
   [详细的对话规则和约束]
```

#### 1.2 关键实现 ([`ConversationManager.gd:128-185`](script/ai/ConversationManager.gd#L128-L185))

```gdscript
func build_dialog_prompt(...) -> String:
    # 1. 获取故事背景
    var background_prompt = BackgroundStoryManager.generate_background_prompt()

    # 2. 构建基础角色信息
    var prompt = "你是一个员工，名字是%s。你的职位是：%s。你的性格是：%s。你的说话风格是：%s。" % [
        speaker.name,
        speaker_personality["position"],
        speaker_personality["personality"],
        speaker_personality["speaking_style"]
    ]

    # 3. 依次添加各个模块
    prompt += "\n\n" + background_prompt
    prompt += company_basic_info
    prompt += company_info
    prompt += speaker_status  # 包含记忆信息
    prompt += speaker_tasks

    # 4. 添加听众信息（不包含对方记忆）
    prompt += "\n\n你正在与%s交谈。" % listener.name

    # 5. 添加对话历史
    if chat_history != "":
        prompt += "\n\n你们之前的对话记录：\n" + chat_history

    # 6. 添加对话约束
    prompt += "\n\n请根据你的性格、当前状态、心情、任务和与对方的关系，生成一段自然的对话。"
    prompt += "\n注意："
    prompt += "\n- 体现出你的性格特点和说话风格"
    prompt += "\n- 考虑你当前的心情和健康状况"
    prompt += "\n- 根据你们的关系程度调整亲密度"
    prompt += "\n- 如果有相关记忆，可以提及"
    prompt += "\n- 可以结合你的当前任务来聊天,当前突发的记忆优先级大于任务。"
    prompt += "\n- 保持对话自然流畅，不要过于正式"
    prompt += "\n- 对话长度控制在1-3句话，30字以内"
    prompt += "\n- 只返回你要说的话，不要加任何描述、动作或其他内容"
    prompt += "\n- 像真人一样直接说话，不要有'你说：'这样的前缀"

    return prompt
```

### 2. AI 决策 Prompt 构建 (AIAgent.gd)

#### 2.1 行动决策 Prompt 结构

```
1. 角色完整身份信息
   "你是[公司名]的员工，名字是[角色名]，职位是[职位]"
   "性格：[性格描述]"
   "说话风格：[说话风格]"
   "工作职责：[工作职责]"
   "工作习惯：[工作习惯]"

2. 公司信息和员工名单
   [公司基本信息和产品介绍]
   [所有员工名单及职位]

3. 角色详细状态信息
   - 存款：[金额]元
   - 心情状态：[状态]
   - 健康状况：[状况]
   - 记忆信息：[格式化的记忆列表]
   - 情感关系：[对其他角色的关系强度]

4. 任务信息
   [当前任务列表，按优先级排序]

5. 环境信息
   [当前房间描述、物品信息、其他角色信息]

6. 决策指导
   "根据以上信息选择最合适的行动："
   "1. 移动到某个位置"
   "2. 与某个角色对话"
   "3. 执行当前任务"
   "4. 休息或放松"
```

#### 2.2 关键实现 ([`AIAgent.gd:510-540`](script/ai/AIAgent.gd#L510-L540))

```gdscript
func build_decision_prompt() -> String:
    var personality = CharacterPersonality.get_personality(character.name)

    var prompt = "你是%s的员工，名字是%s，职位是%s\n" % [
        BackgroundStoryManager.get_current_company_name(),
        character.name,
        personality["position"]
    ]

    prompt += "性格：%s\n" % personality["personality"]
    prompt += "说话风格：%s\n" % personality["speaking_style"]
    prompt += "工作职责：%s\n" % personality["work_duties"]
    prompt += "工作习惯：%s\n" % personality["work_habits"]

    # 添加公司信息
    prompt += get_company_basic_info()
    prompt += get_company_employees_info()

    # 添加状态信息（包含记忆）
    prompt += get_character_status_info(character)

    # 添加任务信息
    prompt += get_character_task_info(character)

    # 添加环境描述
    prompt += "\n" + generate_scene_description()

    # 添加决策指导
    prompt += "\n请根据你的职位、性格、当前个人状态（包括心情、健康、财务状况）、记忆、情感关系、当前任务列表以及当前环境信息，综合考虑在这个情境下最合理的行动。"

    return prompt
```

### 3. 公司信息生成

#### 3.1 公司基本信息 ([`AIAgent.gd:327-334`](script/ai/AIAgent.gd#L327-L334))

```gdscript
func get_company_basic_info() -> String:
    var company_info = "\n\n公司基本信息："
    company_info += "\n你们公司的主要产品是《CountSheep》小游戏。"
    company_info += "\n游戏宣传语：Can't Sleep? Count Sheep"
    company_info += "\n游戏玩法：通过让用户数手机屏幕上跳过的小羊，然后有九宫格数字按钮来计数得分。"
    company_info += "\n该游戏目前十分流行，吸引了许多跟时髦的小青年充值购买小羊皮肤和按键皮肤。"
    return company_info
```

#### 3.2 员工名单信息 ([`AIAgent.gd:315-324`](script/ai/AIAgent.gd#L315-L324))

```gdscript
func get_company_employees_info() -> String:
    var employees_info = "\n\n公司员工名单及职位信息："

    # 遍历CharacterPersonality中的所有角色配置
    for character_name in CharacterPersonality.PERSONALITY_CONFIG:
        var personality = CharacterPersonality.PERSONALITY_CONFIG[character_name]
        employees_info += "\n- %s：%s" % [character_name, personality["position"]]

    employees_info += "\n注意：在生成任何内容时，只能提及以上列出的员工，不要创造新的角色名字。"
    return employees_info
```

## 🌐 API 配置与调用系统

### 1. API 管理器 (APIManager.gd)

#### 1.1 核心功能

- **统一 API 调用接口** - 支持多种 AI 服务商
- **角色独立配置** - 每个角色可使用不同的 AI 模型
- **异步请求处理** - 非阻塞的 HTTP 请求管理
- **自动清理机制** - 请求完成后自动清理 HTTP 节点

#### 1.2 API 调用流程

```gdscript
func generate_dialog(prompt: String, character_name: String = "") -> HTTPRequest:
    # 1. 确保节点初始化
    if not is_inside_tree():
        return null

    # 2. 创建HTTP请求节点
    var http_request = HTTPRequest.new()
    http_request.name = "HTTPRequest_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
    add_child(http_request)

    # 3. 设置自动清理
    http_request.request_completed.connect(func(result, response_code, headers, body):
        get_tree().create_timer(1.0).timeout.connect(func():
            if http_request and is_instance_valid(http_request):
                remove_child(http_request)
                http_request.queue_free()
        )
    )

    # 4. 获取角色专用AI设置
    var ai_settings = current_settings
    if character_name != "":
        ai_settings = SettingsManager.get_character_ai_settings(character_name)

    # 5. 构建请求
    var headers = APIConfig.build_headers(ai_settings.api_type, ai_settings.api_key)
    var data = JSON.stringify(APIConfig.build_request_data(ai_settings.api_type, ai_settings.model, prompt))
    var url = APIConfig.get_url(ai_settings.api_type, ai_settings.model)

    # 6. 发送请求
    http_request.request(url, headers, HTTPClient.METHOD_POST, data)
    return http_request
```

### 2. API 配置管理 (APIConfig.gd)

#### 2.1 支持的 API 类型

```gdscript
enum APIType {
    OLLAMA,            # 本地Ollama
    LMSTUDIO,          # LM Studio
    OPENAI,            # OpenAI API
    DEEPSEEK,          # DeepSeek
    DOUBAO,            # 豆包
    GEMINI,            # Google Gemini
    CLAUDE,            # Anthropic Claude
    SILICONFLOW,       # SiliconFlow
    KIMI,              # Kimi
    OPENAI_COMPATIBLE  # 通用OpenAI兼容接口
}
```

#### 2.2 配置数据结构

```yaml
# config/content/ai/models.yml
providers:
  openai:
    display_name: "OpenAI"
    base_url: "https://api.openai.com/v1"
    endpoints:
      chat: "/chat/completions"
    models:
      - "gpt-4"
      - "gpt-3.5-turbo"
    requires_api_key: true
    headers_template:
      "Content-Type": "application/json"
      "Authorization": "Bearer {api_key}"

  lmstudio:
    display_name: "LM Studio"
    base_url: "http://localhost:1234/v1"
    endpoints:
      chat: "/chat/completions"
    models:
      - "qwen/qwen3-vl-4b"
    requires_api_key: false
```

#### 2.3 核心接口

```gdscript
# 获取所有API类型
static func get_api_types() -> Array[String]

# 获取某个API的所有模型
static func get_models(api_type: String) -> Array[String]

# 构建请求头
static func build_headers(api_type: String, api_key: String) -> Array[String]

# 构建请求数据
static func build_request_data(api_type: String, model: String, prompt: String) -> Dictionary

# 获取API URL
static func get_url(api_type: String, model: String) -> String

# 解析API响应
static func parse_response(api_type: String, response, character_name: String = "") -> String
```

### 3. 设置管理器 (SettingsManager.gd)

#### 3.1 设置结构

```gdscript
# 默认AI设置
var current_settings = {
    "api_type": "LMStudio",
    "model": "qwen/qwen3-vl-4b",
    "api_key": "",
    "show_ai_model_label": true,
    # 显示设置...
}

# 角色独立AI设置
var character_ai_settings = {
    "Stephen": {
        "api_type": "OpenAI",
        "model": "gpt-4",
        "api_key": "sk-..."
    },
    "Alice": {
        "api_type": "LMStudio",
        "model": "qwen/qwen3-vl-4b"
    }
}
```

#### 3.2 角色独立 AI 配置

```gdscript
# 获取角色专用AI设置
func get_character_ai_settings(character_name: String) -> Dictionary:
    if character_name in character_ai_settings:
        return character_ai_settings[character_name]
    else:
        return current_settings  # 使用默认设置

# 设置角色专用AI配置
func set_character_ai_settings(character_name: String, settings: Dictionary):
    character_ai_settings[character_name] = settings
    save_character_ai_settings()
    settings_changed.emit(character_ai_settings)
```

## 🔄 完整调用流程

### 1. 对话生成流程

```
用户触发对话
    ↓
ConversationManager.start_conversation()
    ↓
build_dialog_prompt()
    ↓
1. 获取角色人设 (CharacterPersonality)
2. 获取背景故事 (BackgroundStoryManager)
3. 获取角色状态 (包含记忆)
4. 获取公司信息
5. 获取对话历史
6. 组装完整prompt
    ↓
APIManager.generate_dialog(prompt, character_name)
    ↓
1. 获取角色AI设置 (SettingsManager)
2. 构建API请求 (APIConfig)
3. 发送HTTP请求
    ↓
解析AI响应
    ↓
显示对话气泡 + 保存记忆 + 更新对话历史
```

### 2. AI 决策流程

```
定时器触发 (每60秒)
    ↓
AIAgent.make_decision()
    ↓
build_decision_prompt()
    ↓
1. 获取角色人设和背景
2. 获取角色状态 (包含记忆、情感关系)
3. 获取当前任务
4. 获取环境信息
5. 组装决策prompt
    ↓
APIManager.generate_decision(prompt, character_name)
    ↓
解析决策结果 (移动/对话/任务/休息)
    ↓
执行相应行动
```

## 🎛️ 配置管理最佳实践

### 1. 角色配置原则

- **一致性** - 角色性格与职位匹配
- **多样性** - 不同角色有明显的性格差异
- **真实感** - 避免过于刻板或夸张的设定
- **互动性** - 考虑角色间的化学反应

### 2. Prompt 设计原则

- **层次化** - 从基础信息到具体约束，逻辑清晰
- **上下文丰富** - 提供足够的信息让 AI 理解场景
- **约束明确** - 清晰定义输出格式和内容要求
- **个性化** - 体现角色特色和当前状态

### 3. API 配置策略

- **灵活切换** - 支持运行时切换不同的 AI 模型
- **角色差异化** - 重要角色使用更强的模型
- **成本控制** - 根据场景选择合适的模型
- **容错处理** - API 失败时的降级策略

## 📊 性能优化建议

### 1. Prompt 优化

- **长度控制** - 避免过长的 prompt 影响响应速度
- **信息筛选** - 只包含最相关的历史信息
- **缓存机制** - 缓存不变的公司信息和背景设定
- **分批处理** - 大量信息分批提供给 AI

### 2. API 调用优化

- **请求合并** - 相同角色的多个请求合并处理
- **异步处理** - 避免阻塞主线程
- **错误重试** - 实现智能重试机制
- **响应缓存** - 缓存常见问题的响应

### 3. 内存管理

- **定期清理** - 清理过期的 HTTP 请求节点
- **状态重置** - 及时结束不需要的对话状态
- **数据压缩** - 压缩存储的历史数据

---

_文档版本: v1.0_
_最后更新: 2024-11-10_
_维护者: AI 开发团队_
