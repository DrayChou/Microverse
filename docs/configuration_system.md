# Microverse 配置系统使用指南

## 概述

Microverse游戏现在实现了完整的YAML配置系统，实现了最大程度的配置与代码分离。策划人员可以直接通过编辑YAML配置文件来更新游戏内容，无需修改代码。

## 配置文件结构

```
config/
├── content/                    # 内容配置
│   ├── package.yml            # 包信息
│   ├── characters.yml         # 角色配置
│   ├── scenes.yml             # 场景配置
│   ├── ai_models.yml          # AI模型配置
│   └── background_stories.yml # 背景故事配置
└── ui/                        # UI和系统配置
    ├── ui_config.yml          # UI界面配置
    ├── camera_config.yml      # 相机控制配置
    └── game_settings.yml      # 游戏设置配置
```

## 配置文件详解

### 1. 角色配置 (config/content/characters.yml)

管理所有角色的详细信息，包括人设、外观、AI设置等。

```yaml
characters:
  stephen:
    display_name: "史蒂芬"
    position: "SleepySheep公司老板"
    personality: |
      角色性格描述...
    speaking_style: |
      角色说话风格...
    ai_settings:
      api_type: "OpenAI"
      model: "gpt-4o-mini"
      temperature: 0.7
    appearance:
      sprite_sheet: "res://asset/characters/body/stephen.png"
      scale: 1.0
      color_tint: "#FFFFFF"
      animations:
        idle: "res://asset/characters/animations/stephen_idle.png"
        walk: "res://asset/characters/animations/stephen_walk.png"
```

**添加新角色：**
1. 在`characters.yml`中添加新的角色条目
2. 确保角色名称唯一
3. 准备对应的美术资源文件
4. 重启游戏即可生效

### 2. UI配置 (config/ui/ui_config.yml)

管理所有用户界面元素的配置。

```yaml
ui_config:
  character_detail:
    labels:
      name: "姓名："
      money: "存款："
      mood: "心情："
      health: "健康："

  medical_system:
    diseases:
      - id: "cold"
        name: "感冒"
        severity_min: 1
        severity_max: 3

    emotions:
      - id: "like"
        name: "喜欢"
        default_strength: 5

  task_system:
    max_tasks: 50
    task_pool:
      office_tasks:
        - "检查邮件"
        - "整理工作区"
```

**自定义UI内容：**
- 修改标签文本：编辑`labels`部分
- 添加疾病类型：在`diseases`数组中添加新条目
- 自定义任务池：编辑`task_pool`部分的任务列表

### 3. 相机配置 (config/ui/camera_config.yml)

管理相机行为和控制参数。

```yaml
camera_config:
  movement:
    follow_speed: 5.0
    drag_speed: 1.0

  zoom_levels:
    global: 0.8
    character: 1.5
    min_zoom: 0.5
    max_zoom: 3.0

  map:
    center: [576, 320]
    bounds: [0, 0, 1152, 640]
```

**调整相机行为：**
- 修改跟随速度：调整`follow_speed`值
- 调整缩放级别：修改`zoom_levels`中的数值
- 更改地图中心：修改`center`坐标

### 4. 游戏设置配置 (config/ui/game_settings.yml)

管理游戏的基础设置和选项。

```yaml
game_settings:
  display:
    default_resolution: [1280, 720]
    supported_resolutions:
      - [1280, 720]
      - [1920, 1080]
      - [2560, 1440]

  audio:
    master_volume: 1.0
    music_volume: 0.8

  localization:
    default_language: "zh-CN"
    supported_languages:
      - code: "zh-CN"
        name: "简体中文"
```

### 5. AI模型配置 (config/content/ai_models.yml)

管理AI模型提供商和模型设置。

```yaml
ai_models:
  providers:
    LMStudio:
      display_name: "LMStudio (本地)"
      base_url: "http://localhost:1234/v1"
      models:
        - "qwen/qwen3-vl-4b"
        - "gemma-2b"
```

### 6. 背景故事配置 (config/content/background_stories.yml)

管理不同场景的背景故事配置。

```yaml
background_stories:
  office:
    display_name: "办公室"
    company:
      name: "SleepySheep公司"
      description: "创新驱动的科技公司"
    environment:
      description: "现代化开放式办公环境"
    social_rules:
      - "保持专业形象"
      - "积极沟通协作"
```

## 配置系统API

### ContentManager

ContentManager是配置系统的核心管理器，提供统一的配置访问接口：

```gdscript
# 获取角色配置
var content_manager = ContentManager.get_instance()
var character_config = content_manager.get_character_config("stephen")

# 获取UI配置
var ui_config = content_manager.get_ui_config()
var labels = content_manager.get_ui_config_section("character_detail.labels")

# 获取相机配置
var camera_config = content_manager.get_camera_config()
var zoom_levels = content_manager.get_camera_config_section("zoom_levels")

# 重新加载配置
content_manager.reload_configs()
```

## 配置验证和错误处理

系统具有完善的配置验证机制：

1. **YAML格式验证**：自动检查YAML文件格式是否正确
2. **结构验证**：验证必需字段是否存在
3. **默认值回退**：配置加载失败时使用默认值
4. **详细日志**：提供配置加载过程的详细日志信息

## 最佳实践

### 1. 添加新角色

1. **准备美术资源**：
   ```
   asset/characters/body/new_character.png
   asset/characters/animations/new_character_idle.png
   asset/characters/animations/new_character_walk.png
   asset/characters/animations/new_character_talk.png
   ```

2. **配置角色信息**：
   ```yaml
   characters:
     new_character:
       display_name: "新角色"
       position: "职位描述"
       personality: |
         详细的性格描述...
       ai_settings:
         model: "your-preferred-model"
       appearance:
         sprite_sheet: "res://asset/characters/body/new_character.png"
   ```

3. **测试验证**：重启游戏并测试新角色的功能和外观

### 2. 自定义UI元素

1. **修改标签文本**：
   ```yaml
   ui_config:
     character_detail:
       labels:
         name: "名字："
         money: "资金："
   ```

2. **添加新疾病类型**：
   ```yaml
   medical_system:
     diseases:
       - id: "headache"
         name: "头痛"
         severity_min: 2
         severity_max: 6
   ```

3. **自定义任务池**：
   ```yaml
   task_system:
     task_pool:
       office_tasks:
         - "你的自定义任务"
         - "另一个任务"
   ```

### 3. 调整相机参数

1. **修改相机速度**：
   ```yaml
   camera_config:
     movement:
       follow_speed: 8.0  # 更快的跟随速度
     zoom_control:
       zoom_speed: 0.2    # 更快的缩放速度
   ```

2. **调整缩放级别**：
   ```yaml
   zoom_levels:
     global: 0.6          # 更广的视角
     character: 2.0       # 更近的角色视角
   ```

## 配置热重载

系统支持配置的热重载（开发阶段）：

```gdscript
# 在游戏中重新加载配置
ContentManager.get_instance().reload_configs()
```

**注意**：生产环境建议重启游戏以确保所有配置正确生效。

## 故障排除

### 常见问题

1. **配置文件未生效**：
   - 检查YAML文件格式是否正确
   - 查看控制台日志中的配置加载信息
   - 确认文件路径和文件名正确

2. **角色外观异常**：
   - 检查美术资源文件是否存在
   - 验证`appearance`配置中的资源路径
   - 确认颜色格式正确（如 "#FFFFFF"）

3. **UI元素显示异常**：
   - 检查`ui_config.yml`中的标签配置
   - 确认疾病和情感配置格式正确
   - 验证任务池配置不为空

### 调试技巧

1. **查看配置统计**：
   ```gdscript
   var stats = ContentManager.get_instance().get_config_stats()
   print("配置统计: ", stats)
   ```

2. **检查特定配置**：
   ```gdscript
   var ui_config = ContentManager.get_instance().get_ui_config()
   print("UI配置: ", ui_config)
   ```

3. **启用详细日志**：在配置文件中设置调试模式

## 版本控制

### 配置文件版本管理

1. **配置文件变更**：所有配置文件变更都应记录在版本控制中
2. **向后兼容**：新版本配置应保持与旧版本的兼容性
3. **配置迁移**：提供配置格式变更时的迁移指南

### 推荐工作流

1. **策划编辑配置**：在开发环境中编辑YAML文件
2. **本地测试**：验证配置变更效果
3. **提交审查**：提交配置变更到版本控制
4. **集成测试**：在测试环境中验证完整功能

## 总结

通过完整的YAML配置系统，Microverse实现了：

- ✅ **配置与代码完全分离**
- ✅ **策划可直接编辑游戏内容**
- ✅ **支持热重载和实时预览**
- ✅ **完善的错误处理和验证**
- ✅ **模块化的配置结构**
- ✅ **易于扩展和维护**

这个配置系统为游戏的长期开发和内容更新提供了坚实的基础。