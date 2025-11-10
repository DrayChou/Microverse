# 配置目录结构重新组织

## 🔍 问题分析

之前的 `config/content` 目录混合了游戏内容和系统配置，分类不够清晰。

## ✅ 重新组织后的正确结构

### **`config/content/`** - 游戏内容和资产
```
config/content/
├── package.yml                           # 游戏包信息
├── ai/models.yml                         # AI模型配置（内容相关）
├── background_stories.yml                # 背景故事
├── characters/
│   ├── characters.yml                    # 角色基本信息
│   └── personalities.yml                 # 角色性格
└── stories/main.yml                      # 故事线
```

### **`config/systems/`** - 系统和引擎配置
```
config/systems/
├── physics/movement.yml                  # 物理系统
├── audio/master.yml                      # 音频系统
├── graphics/animations.yml              # 图形系统
├── input/controls.yml                    # 输入系统
├── ui/layout.yml                         # UI系统
├── camera/movement.yml                   # 摄像机系统
├── animations/character.yml             # 动画系统
├── dialogue/system.yml                  # 对话系统
├── gameplay/movement.yml                 # 游戏玩法系统
├── scenes/
│   ├── scenes.yml                        # 场景管理
│   ├── scene_paths.yml                   # 场景路径
│   └── locations.yml                     # 地点配置
```

### **`config/runtime/`** - 运行时配置
```
config/runtime/
├── storage/paths.yml                     # 存储路径
├── save/system.yml                       # 存档系统
├── network/client.yml                    # 网络客户端
└── debug/development.yml                 # 调试配置
```

### **`config/ui/`** - UI专用配置
```
config/ui/
├── camera_config.yml                     # UI摄像机
├── game_settings.yml                     # 游戏设置
└── ui_config.yml                         # UI配置
```

## 📊 配置文件统计

- **content**: 6个文件（游戏内容）
- **systems**: 11个文件（系统配置）
- **runtime**: 4个文件（运行时配置）
- **ui**: 3个文件（UI配置）
- **总计**: 24个配置文件

## 🔧 需要的代码更新

### ContentManager.gd 需要更新的部分：

1. **删除的方法**（已移到 systems/）：
   - `_load_background_configs()` → `_load_locations_system_configs()`
   - `_load_dialogue_configs()` → `_load_dialogue_system_configs()`

2. **新增的系统配置加载方法**：
   - `_load_animation_system_configs()`
   - `_load_dialogue_system_configs()`
   - `_load_gameplay_system_configs()`
   - `_load_scenes_system_configs()`
   - `_load_scene_paths_system_configs()`
   - `_load_locations_system_configs()`

3. **更新的配置访问方法**：
   - `get_dialogue_config()` → 从系统配置加载
   - `get_background_config()` → 从系统配置加载

## 🎯 分类原则

- **content/**: 游戏内容和数据（角色、故事、AI模型等）
- **systems/**: 引擎和技术系统配置（物理、音频、UI、对话等）
- **runtime/**: 运行时行为配置（存档、网络、调试等）
- **ui/**: 纯UI相关的配置

## 📝 优势

1. **清晰的职责分离**：内容与技术分开管理
2. **更好的维护性**：相关配置集中在一起
3. **策划友好**：content/ 目录下的文件都是策划可以直接编辑的游戏内容
4. **开发友好**：systems/ 目录下的文件都是技术人员关心的技术配置

## ⚠️ 注意事项

1. 需要更新所有引用这些配置的代码
2. 测试脚本需要更新以匹配新的路径
3. 确保所有配置文件的 YAML 结构与新路径对应