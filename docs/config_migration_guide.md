# 配置结构迁移指南

## 📋 概述

本文档详细说明了如何将Microverse项目从旧的配置目录结构迁移到新的、更合理的配置结构。新结构更加清晰、模块化，便于长期维护和团队协作。

## 🎯 迁移目标

1. **清晰的职责分离**：按功能域划分配置文件
2. **更好的可维护性**：相关配置集中管理
3. **团队协作友好**：不同团队专注不同目录
4. **Godot 4.4特性支持**：充分利用新引擎特性

## 📁 新旧结构对比

### 旧结构问题

```
config/
├── content/                    # 混乱的分类
│   ├── package.yml
│   ├── characters.yml          # 基础信息+性格混在一起
│   ├── scenes.yml
│   ├── ai_models.yml
│   ├── background_stories.yml
│   ├── gameplay/               # 和content混合
│   │   └── movement.yml
│   ├── scenes/                  # 路径配置在这里
│   │   └── scene_paths.yml
│   ├── storage/                 # 运行时配置在这里
│   │   └── paths.yml
│   └── animations/             # 图形配置在这里
│       └── character.yml
└── ui/                         # UI和系统混在一起
    ├── ui_config.yml           # UI具体配置
    ├── camera_config.yml         # 系统配置
    └── game_settings.yml         # 系统配置
```

### 新结构优势

```
config/
├── content/                          # 🎮 纯游戏内容
│   ├── package.yml                  # 包信息
│   ├── characters/                   # 👥 角色相关
│   │   ├── characters.yml           # 基础信息
│   │   └── personalities.yml         # 性格对话
│   ├── world/                        # 🌍 世界观
│   │   ├── scenes.yml               # 场景信息
│   │   └── background_stories.yml   # 背景故事
│   ├── ai/                           # 🤖 AI系统
│   │   └── models.yml               # AI模型
│   └── gameplay/                     # 🎯 游戏规则
│       └── rules.yml                # 游戏机制
├── systems/                          # ⚙️ 技术系统
│   ├── physics/                      # 物理系统
│   │   └── movement.yml             # 移动和导航
│   ├── graphics/                     # 图形渲染
│   │   └── animations.yml           # 动画系统
│   ├── camera/                       # 相机系统
│   │   └── movement.yml             # 相机控制
│   └── ui/                           # UI系统
│       └── layout.yml               # UI布局
└── runtime/                          # 🚀 运行时环境
    └── storage/                      # 存储
        └── paths.yml                 # 存储配置
```

## 🔄 迁移映射表

### 内容类配置迁移

| 旧路径 | 新路径 | 说明 |
|--------|--------|------|
| `config/content/characters.yml` | `config/content/characters/characters.yml` | 角色基础信息 |
| `config/content/background_stories.yml` | `config/content/world/background_stories.yml` | 背景故事 |
| `config/content/ai_models.yml` | `config/content/ai/models.yml` | AI模型配置 |
| `config/content/scenes.yml` | `config/content/world/scenes.yml` | 场景配置 |

### 系统类配置迁移

| 旧路径 | 新路径 | 说明 |
|--------|--------|------|
| `config/content/gameplay/movement.yml` | `config/systems/physics/movement.yml` | 物理移动系统 |
| `config/content/animations/character.yml` | `config/systems/graphics/animations.yml` | 动画系统 |
| `config/content/scenes/scene_paths.yml` | `config/runtime/storage/paths.yml` (部分) | 场景路径 |
| `config/ui/camera_config.yml` | `config/systems/camera/movement.yml` | 相机控制 |
| `config/ui/ui_config.yml` | `config/systems/ui/layout.yml` | UI布局 |

### 运行时配置迁移

| 旧路径 | 新路径 | 说明 |
|--------|--------|------|
| `config/content/storage/paths.yml` | `config/runtime/storage/paths.yml` | 存储系统 |
| `config/ui/game_settings.yml` | 多个文件拆分 | 根据功能拆分 |

## 🚀 迁移步骤

### 第一阶段：创建新结构

1. **创建目录结构**
   ```bash
   mkdir -p config/content/characters
   mkdir -p config/content/world
   mkdir -p config/content/ai
   mkdir -p config/content/gameplay
   mkdir -p config/systems/physics
   mkdir -p config/systems/graphics
   mkdir -p config/systems/camera
   mkdir -p config/systems/ui
   mkdir -p config/runtime/storage
   ```

2. **迁移现有文件**
   - 已完成基础文件创建
   - 需要拆分和重组配置内容

### 第二阶段：内容重组

#### 2.1 角色配置拆分

**原文件**: `config/content/characters.yml`
**拆分为**:
- `config/content/characters/characters.yml` - 基础信息、AI设置、外观
- `config/content/characters/personalities.yml` - 详细性格、说话风格

**迁移示例**:
```yaml
# 新的 characters.yml 侧重基础信息
stephen:
  display_name: "史蒂芬"
  position: "SleepySheep公司老板"
  ai_settings:
    api_type: "OpenAI"
    model: "gpt-4o-mini"
  appearance:
    sprite_sheet: "res://asset/characters/body/stephen.png"

# 新的 personalities.yml 侧重性格描述
stephen:
  personality: "奥斯卡级虚伪表演家..."
  speaking_style: "张嘴就是'期权池已备好'..."
  work_duties: "每周发布新的'三年愿景'..."
```

#### 2.2 UI配置拆分

**原文件**: `config/ui/ui_config.yml`
**拆分为**:
- `config/systems/ui/layout.yml` - 布局和控件
- `config/systems/ui/controls.yml` - 交互控制
- `config/systems/ui/themes.yml` - 主题样式

### 第三阶段：代码适配

#### 3.1 ContentManager 重构

**新的配置类别枚举**:
```gdscript
enum ConfigCategory {
    CONTENT,       # 游戏内容
    SYSTEMS,       # 技术系统
    RUNTIME,       # 运行时
    LOCALIZATION,  # 本地化
    DEVELOPMENT    # 开发配置
}
```

**新的加载方法**:
```gdscript
func load_config_by_category(category: ConfigCategory, config_name: String) -> Dictionary:
    var path = get_config_path(category, config_name)
    return load_yaml_config(path).data

func get_config_path(category: ConfigCategory, config_name: String) -> String:
    match category:
        ConfigCategory.CONTENT:
            return "res://config/content/%s/%s.yml" % [config_name, config_name]
        ConfigCategory.SYSTEMS:
            return "res://config/systems/%s/%s.yml" % [config_name, config_name]
        ConfigCategory.RUNTIME:
            return "res://config/runtime/%s/%s.yml" % [config_name, config_name]
```

#### 3.2 代码中的配置调用更新

**旧的调用方式**:
```gdscript
# 获取移动配置
var movement_config = ContentManager.get_instance().get_movement_config()

# 获取UI配置
var ui_config = ContentManager.get_instance().get_ui_config()
```

**新的调用方式**:
```gdscript
# 获取物理移动配置
var movement_config = ContentManager.get_instance().get_config(
    ConfigCategory.SYSTEMS, "physics/movement"
)

# 获取UI布局配置
var ui_config = ContentManager.get_instance().get_config(
    ConfigCategory.SYSTEMS, "ui/layout"
)

# 获取角色基础信息
var character_info = ContentManager.get_instance().get_config(
    ConfigCategory.CONTENT, "characters"
)

# 获取角色性格
var personalities = ContentManager.get_instance().get_config(
    ConfigCategory.CONTENT, "characters/personalities"
)
```

### 第四阶段：验证和测试

#### 4.1 配置完整性检查

**检查清单**:
- [ ] 所有旧配置文件都有对应的新位置
- [ ] 新配置文件内容完整
- [ ] 代码中的配置调用已更新
- [ ] 配置加载路径正确
- [ ] 没有配置丢失或重复

#### 4.2 功能测试

**测试要点**:
- 游戏启动时配置加载正常
- 角色信息和性格都能正确获取
- 物理移动系统工作正常
- UI界面布局正确
- 存档系统功能正常

## ⚠️ 注意事项

### 1. 兼容性处理

- 保持旧的API方法，内部重定向到新结构
- 逐步迁移，不要一次性删除旧配置
- 提供迁移工具帮助更新代码

### 2. 配置验证

- 在ContentManager中添加配置验证
- 确保新配置格式正确
- 提供友好的错误提示

### 3. 团队培训

- 文档化新的配置结构
- 提供配置编写指南
- 培训团队成员使用新结构

## 📊 迁移收益

### 1. 维护性提升
- 配置职责清晰，便于定位
- 相关配置集中，修改影响范围明确
- 团队协作减少冲突

### 2. 扩展性增强
- 新功能有明确的放置位置
- 易于添加新的配置类别
- 支持更细粒度的配置管理

### 3. 团队效率
- 不同团队专注不同目录
- 减少配置文件冲突
- 提高并行工作效率

## 🔧 迁移工具

### 配置迁移脚本

可以创建一个迁移脚本来自动处理大部分迁移工作：

```python
#!/usr/bin/env python3
# config_migrator.py

import os
import yaml
import shutil

class ConfigMigrator:
    def __init__(self, old_root, new_root):
        self.old_root = old_root
        self.new_root = new_root
        self.migration_map = self.get_migration_map()

    def get_migration_map(self):
        return {
            'content/characters.yml': 'content/characters/characters.yml',
            'ui/camera_config.yml': 'systems/camera/movement.yml',
            'ui/ui_config.yml': 'systems/ui/layout.yml',
            # ... 其他映射
        }

    def migrate_all(self):
        for old_path, new_path in self.migration_map.items():
            self.migrate_file(old_path, new_path)

    def migrate_file(self, old_path, new_path):
        old_file = os.path.join(self.old_root, old_path)
        new_file = os.path.join(self.new_root, new_path)

        if os.path.exists(old_file):
            # 读取旧配置
            with open(old_file, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)

            # 处理配置内容
            processed_config = self.process_config(old_path, config)

            # 创建新目录
            os.makedirs(os.path.dirname(new_file), exist_ok=True)

            # 写入新配置
            with open(new_file, 'w', encoding='utf-8') as f:
                yaml.dump(processed_config, f, default_flow_style=False, allow_unicode=True)

            print(f"迁移完成: {old_path} -> {new_path}")

    def process_config(self, old_path, config):
        # 根据文件路径处理配置内容
        if 'characters.yml' in old_path:
            return self.split_character_config(config)
        elif 'ui_config.yml' in old_path:
            return self.split_ui_config(config)
        else:
            return config

    def split_character_config(self, config):
        # 拆分角色配置为基本信息和性格
        basic_info = {}
        personalities = {}

        if 'characters' in config:
            for name, data in config['characters'].items():
                basic_info[name] = {
                    'display_name': data.get('display_name'),
                    'position': data.get('position'),
                    'age': data.get('age'),
                    'ai_settings': data.get('ai_settings'),
                    'appearance': data.get('appearance')
                }

                personalities[name] = {
                    'personality': data.get('personality'),
                    'speaking_style': data.get('speaking_style'),
                    'work_duties': data.get('work_duties'),
                    'work_habits': data.get('work_habits')
                }

        return {'content': {'characters': basic_info, 'personalities': personalities}}

# 使用示例
if __name__ == "__main__":
    migrator = ConfigMigrator("config_old", "config_new")
    migrator.migrate_all()
```

## 📚 相关文档

- [配置结构重设计](config_structure_redesign.md)
- [Godot 4.4配置化改造指南](godot44_configuration_guide.md)
- [YAML配置系统使用指南](configuration_system.md)

## 🎯 下一步计划

1. **实施迁移脚本**：自动化大部分迁移工作
2. **更新ContentManager**：支持新的配置结构
3. **全面测试**：确保所有功能正常
4. **团队培训**：让团队熟悉新结构
5. **文档更新**：更新所有相关文档

通过这次迁移，Microverse项目的配置系统将更加合理、清晰，便于长期维护和团队协作。