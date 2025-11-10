# YAML配置系统使用指南

## 📋 概述

Microverse现在使用YAML配置文件来管理角色、场景和AI模型设置。这个系统让添加新角色和修改现有配置变得非常简单，无需修改代码。

## 📁 文件结构

```
config/content/
├── package.yml          # 包信息和元数据
├── characters.yml       # 角色配置
├── scenes.yml           # 场景配置
└── ai_models.yml        # AI模型配置
```

## 👥 角色配置

### 基本结构

在 `config/content/characters.yml` 中定义所有角色：

```yaml
characters:
  stephen:
    display_name: "史蒂芬"
    position: "SleepySheep公司老板"
    personality: |
      角色性格描述，支持多行文本
    speaking_style: |
      角色的说话风格和口头禅
    work_duties: |
      角色的工作职责
    work_habits: |
      角色的工作习惯
    ai_settings:
      api_type: "OpenAI"
      model: "gpt-4o-mini"
      temperature: 0.7
```

### 添加新角色

1. 在 `characters.yml` 的 `characters` 节下添加新角色：
```yaml
characters:
  # ... 现有角色 ...
  new_character:
    display_name: "新角色名"
    position: "职位描述"
    personality: "性格描述"
    speaking_style: "说话风格"
    work_duties: "工作职责"
    work_habits: "工作习惯"
    ai_settings:
      api_type: "OpenAI"
      model: "gpt-4o-mini"
      temperature: 0.7
```

2. 重启游戏，新角色配置会自动加载。

### 修改现有角色

直接编辑对应角色的配置字段，重启游戏后生效。

### 角色字段说明

| 字段 | 必需 | 说明 |
|------|------|------|
| `display_name` | ✓ | 角色的显示名称 |
| `position` | ✓ | 角色的职位 |
| `personality` | ✓ | 角色性格描述 |
| `speaking_style` | ✓ | 角色说话风格 |
| `work_duties` | ✓ | 工作职责 |
| `work_habits` | ✓ | 工作习惯 |
| `ai_settings` | ✓ | AI模型配置 |

### AI设置字段

| 字段 | 说明 | 可选值 |
|------|------|--------|
| `api_type` | AI服务提供商 | `OpenAI`, `LMStudio`, `Claude`, `Gemini`, `DeepSeek`, `Doubao`, `KIMI`, `SiliconFlow` |
| `model` | 模型名称 | 根据提供商选择 |
| `temperature` | 创造性参数 | 0.0-2.0，默认0.7 |

## 🏢 场景配置

### 基本结构

在 `config/content/scenes.yml` 中定义场景：

```yaml
scenes:
  office:
    display_name: "办公室"
    description: "场景描述"
    company_name: "公司名称"
    company_description: "公司描述"
    social_rules:
      - "规则1"
      - "规则2"
    rooms:
      - name: "room_name"
        display_name: "显示名称"
        description: "房间描述"
        position: [x, y]
        size: [width, height]
```

## 🤖 AI模型配置

### 基本结构

在 `config/content/ai_models.yml` 中定义AI提供商：

```yaml
ai_models:
  providers:
    openai:
      display_name: "OpenAI"
      base_url: "https://api.openai.com/v1/chat/completions"
      requires_api_key: true
      request_format: "openai"
      response_format: "openai"
      models:
        - id: "gpt-4o-mini"
          display_name: "GPT-4o Mini"
          context_limit: 128000
          default_temperature: 0.7
```

## 🔧 代码集成

### 在代码中使用新配置系统

```gdscript
# 获取ContentManager实例
var content_manager = get_node("/root/ContentManager")

# 获取角色配置
var character_config = content_manager.get_character_config("stephen")

# 使用CharacterPersonalityClean
var personality = CharacterPersonalityClean.get_personality("stephen")
var ai_settings = CharacterPersonalityClean.get_ai_settings("stephen")
```

## 🚨 注意事项

### 配置文件格式要求

- 使用YAML格式，注意缩进（使用空格，不要使用Tab）
- 字符串值如果包含特殊字符，需要用引号包围
- 多行文本使用 `|` 格式
- 数组使用 `-` 开头

### 常见错误

1. **缩进错误**：
```yaml
# 错误
characters:
stephen:  # 缩进不对
  display_name: "史蒂芬"

# 正确
characters:
  stephen:
    display_name: "史蒂芬"
```

2. **引号缺失**：
```yaml
# 错误
message: This contains: a colon

# 正确
message: "This contains: a colon"
```

3. **特殊字符**：
```yaml
# 错误
tag: #include other.yaml

# 正确
tag: "#include other.yaml"  # 或者使用引号
```

## 🔄 配置更新

1. **编辑YAML文件**
2. **重启游戏** - 配置会在启动时自动加载
3. **检查日志** - 在控制台查看加载状态和错误信息

## 🧪 测试配置

使用测试脚本验证配置：

```gdscript
# 测试角色配置
var config = CharacterPersonalityClean.get_personality("stephen")
print(config.get("display_name", "Unknown"))

# 检查角色是否存在
if CharacterPersonalityClean.has_character("stephen"):
    print("Stephen配置存在")
```

## 📊 配置统计

获取配置使用统计：

```gdscript
# 从CharacterPersonalityClean
var stats = CharacterPersonalityClean.get_config_stats()
print("角色数量: ", stats.config_count)

# 从ContentManager
var content_stats = content_manager.get_config_stats()
print("包信息: ", content_stats.package_name)
```

## 🐛 故障排除

### 配置文件未加载

1. 检查文件路径是否正确
2. 确保YAML格式没有语法错误
3. 查看控制台错误信息

### 角色配置不生效

1. 确保角色名称正确（区分大小写）
2. 检查必需字段是否完整
3. 重启游戏让配置生效

### AI设置问题

1. 确认API类型和模型名称正确
2. 检查API密钥是否设置（如果需要）
3. 查看API相关的错误日志

## 💡 最佳实践

1. **备份配置**：修改前备份原始配置文件
2. **小步修改**：一次只修改一个角色或设置
3. **测试验证**：修改后立即测试功能
4. **版本控制**：使用Git跟踪配置文件变更
5. **文档更新**：重要修改及时更新文档

通过这个YAML配置系统，你可以轻松地管理游戏中的所有角色和AI设置，无需修改任何代码！