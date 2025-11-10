# 配置目录结构重设计方案

## 📋 当前问题分析

当前 `config/` 目录结构存在以下问题：
1. **分类混乱**：gameplay、animations、storage 都在 content 下，但性质不同
2. **层级不一致**：有些是具体配置，有些是配置类别
3. **命名不统一**：缺乏清晰的命名规范
4. **职责不清**：运行时配置和内容配置混合

## 🎯 新的目录结构设计

```
config/
├── content/                          # 🎮 游戏内容配置
│   ├── package.yml                  # 包信息和元数据
│   ├── characters/                   # 👥 角色相关配置
│   │   ├── characters.yml           # 角色基本信息
│   │   ├── personalities.yml         # 角色性格和对话风格
│   │   └── appearances.yml          # 角色外观和动画配置
│   ├── world/                        # 🌍 世界和场景配置
│   │   ├── scenes.yml               # 场景基本信息
│   │   ├── locations.yml            # 地点和位置配置
│   │   └── background_stories.yml   # 背景故事和世界观
│   ├── ai/                           # 🤖 AI系统配置
│   │   ├── models.yml               # AI模型配置
│   │   ├── behaviors.yml            # AI行为配置
│   │   └── conversation.yml          # 对话系统配置
│   └── gameplay/                     # 🎯 游戏玩法配置
│       ├── rules.yml                # 游戏规则和机制
│       ├── difficulty.yml           # 难度设置
│       └── progression.yml          # 进度配置

├── systems/                          # ⚙️ 系统技术配置
│   ├── physics/                      # 🔧 物理系统配置
│   │   ├── movement.yml             # 移动和导航
│   │   ├── collision.yml            # 碰撞检测
│   │   └── navigation.yml           # 寻路系统
│   ├── graphics/                     # 🎨 图形渲染配置
│   │   ├── rendering.yml            # 渲染设置
│   │   ├── animations.yml           # 动画系统
│   │   ├── effects.yml              # 视觉效果
│   │   └── lighting.yml             # 灯光和阴影
│   ├── audio/                        # 🔊 音频系统配置
│   │   ├── master.yml               # 主音频设置
│   │   ├── music.yml                # 背景音乐
│   │   ├── sfx.yml                  # 音效
│   │   └── voice.yml                # 语音
│   ├── ui/                           # 🖼️ 用户界面配置
│   │   ├── layout.yml               # UI布局和尺寸
│   │   ├── themes.yml               # 主题和样式
│   │   ├── controls.yml             # 控件配置
│   │   └── hud.yml                  # HUD元素
│   ├── input/                        # 🎮 输入系统配置
│   │   ├── keyboard.yml             # 键盘控制
│   │   ├── mouse.yml                # 鼠标控制
│   │   ├── gamepad.yml              # 手柄控制
│   │   └── touch.yml                # 触屏控制
│   └── camera/                       # 📷 相机系统配置
│       ├── movement.yml             # 相机移动
│       ├── zoom.yml                 # 缩放控制
│       ├── effects.yml              # 相机特效
│       └── modes.yml                # 相机模式

├── runtime/                          # 🚀 运行时配置
│   ├── storage/                      # 💾 存储和存档
│   │   ├── paths.yml                # 文件路径
│   │   ├── formats.yml              # 存储格式
│   │   ├── compression.yml          # 压缩设置
│   │   └── backup.yml               # 备份策略
│   ├── networking/                   # 🌐 网络配置
│   │   ├── server.yml               # 服务器设置
│   │   ├── client.yml               # 客户端设置
│   │   └── protocols.yml            # 网络协议
│   ├── performance/                  # ⚡ 性能配置
│   │   ├── optimization.yml         # 优化设置
│   │   ├── profiling.yml            # 性能分析
│   │   ├── caching.yml              # 缓存策略
│   │   └── threading.yml            # 线程设置
│   └── platform/                     # 📱 平台特定配置
│       ├── windows.yml              # Windows平台
│       ├── macos.yml                # macOS平台
│       ├── linux.yml                # Linux平台
│       ├── mobile.yml               # 移动平台
│       └── web.yml                  # Web平台

├── localization/                    # 🌍 本地化配置
│   ├── languages.yml                 # 支持的语言
│   ├── fonts/                        # 字体配置
│   │   ├── chinese.yml              # 中文字体
│   │   ├── english.yml              # 英文字体
│   │   └── fallback.yml             # 后备字体
│   └── text/                         # 文本资源
│       ├── zh-CN/                   # 中文文本
│       │   ├── ui.yml               # UI文本
│       │   ├── dialog.yml           # 对话文本
│       │   └── tutorial.yml          # 教程文本
│       └── en-US/                   # 英文文本
│           ├── ui.yml
│           ├── dialog.yml
│           └── tutorial.yml

└── development/                      # 👨‍💻 开发配置
    ├── debugging.yml                 # 调试设置
    ├── logging.yml                   # 日志配置
    ├── testing.yml                   # 测试配置
    ├── editor/                       # 编辑器配置
    │   ├── plugins.yml              # 插件配置
    │   └── shortcuts.yml            # 快捷键
    └── deployment/                   # 部署配置
        ├── build.yml                # 构建设置
        ├── packaging.yml            # 打包配置
        └── release.yml              # 发布设置
```

## 🏗️ 目录设计原则

### 1. **清晰的责任分离**
- **content/**: 游戏内容和数据
- **systems/**: 技术系统配置
- **runtime/**: 运行时环境和平台
- **localization/**: 国际化和本地化
- **development/**: 开发和部署相关

### 2. **层级化组织**
- 按功能域划分（physics、audio、ui等）
- 每个域下按具体功能细分
- 便于团队协作和维护

### 3. **命名规范**
- 文件名使用小写字母和下划线
- 目录名体现功能类别
- 避免缩写，使用描述性名称

### 4. **Godot 4.4 特性考虑**
- 多线程相关配置放在 `runtime/performance/`
- 渲染配置放在 `systems/graphics/`
- 物理优化配置放在 `systems/physics/`

## 🔄 迁移计划

### 第一阶段：重组现有配置

```
# 现有 → 新位置
config/content/gameplay/movement.yml → config/systems/physics/movement.yml
config/content/animations/character.yml → config/systems/graphics/animations.yml
config/content/scenes/scene_paths.yml → config/runtime/storage/paths.yml
config/content/storage/paths.yml → config/runtime/storage/paths.yml
config/ui/camera_config.yml → config/systems/camera/movement.yml
config/ui/ui_config.yml → config/systems/ui/layout.yml
config/ui/game_settings.yml → config/runtime/platform/common.yml
```

### 第二阶段：功能细化

1. **拆分大型配置文件**
2. **创建平台特定配置**
3. **完善开发配置**
4. **建立本地化体系**

### 第三阶段：优化和验证

1. **更新ContentManager**
2. **重构配置加载逻辑**
3. **添加配置验证**
4. **性能优化**

## 🎯 ContentManager 重构建议

```gdscript
# 新的配置加载结构
enum ConfigCategory {
    CONTENT,
    SYSTEMS,
    RUNTIME,
    LOCALIZATION,
    DEVELOPMENT
}

# 按类别加载配置
func load_config_by_category(category: ConfigCategory, config_name: String) -> Dictionary:
    var path = get_config_path(category, config_name)
    return load_yaml_config(path).data

# 配置路径映射
func get_config_path(category: ConfigCategory, config_name: String) -> String:
    match category:
        ConfigCategory.CONTENT:
            return "res://config/content/%s.yml" % config_name
        ConfigCategory.SYSTEMS:
            return "res://config/systems/%s.yml" % config_name
        ConfigCategory.RUNTIME:
            return "res://config/runtime/%s.yml" % config_name
        # ... 其他类别
```

## 📊 预期收益

1. **维护性提升**
   - 清晰的目录结构便于定位
   - 职责分离降低耦合度

2. **协作效率**
   - 不同团队专注不同目录
   - 减少配置冲突

3. **扩展性增强**
   - 新功能有明确的放置位置
   - 易于添加新的配置类别

4. **平台适配**
   - 平台特定配置集中管理
   - 便于跨平台部署

这个新结构更加合理，便于长期维护和团队协作。您觉得这个重设计方案如何？需要我帮您开始实施这个重构吗？