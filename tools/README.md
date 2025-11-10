# YAML 到 JSON 转换工具

本目录包含了用于将 YAML 配置文件转换为 JSON 格式的工具，便于手动编辑和维护配置文件。

## 工具说明

### 1. `yaml_to_json_converter.py` - 专业转换工具
功能全面的转换工具，支持批量处理、验证、备份等高级功能。

**基本用法:**
```bash
# 转换所有YAML文件
python yaml_to_json_converter.py

# 显示配置文件状态
python yaml_to_json_converter.py --status

# 转换单个文件
python yaml_to_json_converter.py --file config/content/ai/models.yml

# 验证JSON文件
python yaml_to_json_converter.py --validate

# 清理YAML文件（试运行）
python yaml_to_json_converter.py --cleanup

# 真正删除YAML文件
python yaml_to_json_converter.py --cleanup --force
```

**高级选项:**
```bash
# 指定配置目录
python yaml_to_json_converter.py --dir config

# 不创建备份
python yaml_to_json_converter.py --no-backup

# 设置JSON缩进
python yaml_to_json_converter.py --indent 4
```

### 2. `quick_convert.py` - 快速转换工具
简单易用的转换脚本，适合快速转换常见问题。

**用法:**
```bash
# 转换所有YAML文件
python quick_convert.py

# 转换指定文件
python quick_convert.py config/content/ai/models.yml
```

## 使用建议

### 工作流程

1. **查看当前状态:**
   ```bash
   python yaml_to_json_converter.py --status
   ```

2. **转换YAML文件:**
   ```bash
   python yaml_to_json_converter.py
   ```

3. **验证转换结果:**
   ```bash
   python yaml_to_json_converter.py --validate
   ```

4. **测试游戏功能:**
   在Godot中运行 `test_json_loading.gd` 测试脚本

5. **清理YAML文件:**
   ```bash
   # 先试运行查看会删除哪些文件
   python yaml_to_json_converter.py --cleanup

   # 确认无误后真正删除
   python yaml_to_json_converter.py --cleanup --force
   ```

### 常见问题处理

**YAML解析错误:**
- 转换工具会自动尝试修复常见的语法问题
- 检查错误日志，手动修复复杂问题
- 确保数组项格式正确：`- "item"` 而不是 `- item`

**编码问题:**
- 所有文件使用UTF-8编码
- 转换工具会自动处理BOM标记

**文件结构:**
- 保持原有的目录结构
- JSON文件会与YAML文件在同一位置

## 配置文件分析结果

根据最新日志分析，当前配置文件状态如下：

### ✅ 正常工作的配置 (JSON优先加载)
- `package.json` - 包配置
- `characters/characters.json` - 角色配置
- `ai/models.json` - AI模型配置
- `background_stories.json` - 背景故事
- `stories/main.json` - 故事线
- `audio/master.json` - 音频系统

### ❌ 需要修复的YAML配置
- `characters/personalities.yml` - 第8行语法错误
- `graphics.yml` - 第266行语法错误
- `input/controls.yml` - 第299行语法错误
- `animations/character.yml` - 第227行语法错误
- `dialogue/system.yml` - 第52行语法错误
- `scenes/scenes.yml` - 第6行语法错误
- `storage/paths.yml` - 第270行语法错误
- `game_settings.yml` - 第10行语法错误

### 🔧 建议操作

1. **使用转换工具修复有问题的YAML文件:**
   ```bash
   python yaml_to_json_converter.py --file config/content/characters/personalities.yml
   # ... 其他有问题的文件
   ```

2. **批量转换所有文件:**
   ```bash
   python yaml_to_json_converter.py
   ```

3. **验证转换结果:**
   ```bash
   python yaml_to_json_converter.py --validate
   ```

4. **测试游戏:**
   运行Godot并查看控制台日志，确认JSON配置正常加载

## 手动编辑建议

JSON配置文件相对于YAML的优势：

### ✅ JSON优势
- **语法简单** - 只需要处理引号、逗号、括号
- **工具支持好** - 所有编辑器都有语法高亮和验证
- **错误信息清晰** - 容易定位问题
- **Godot原生支持** - 无需额外解析器

### 📝 编辑技巧
- 使用支持JSON的编辑器（VS Code、Sublime Text等）
- 开启格式化功能，保持代码整洁
- 使用在线JSON验证器检查语法
- 大文件可以分段编辑和验证

### 🔍 格式规范
```json
{
  "content": {
    "section": {
      "key": "value",
      "array": ["item1", "item2"],
      "nested": {
        "deep": "value"
      }
    }
  }
}
```

## 备份和恢复

转换工具会自动创建备份：
- 备份位置: `backups/` 目录
- 文件名格式: `原文件名_时间戳.yml`
- 包含完整的原始内容

恢复方法：
```bash
# 从备份恢复
cp backups/filename_20251110_163000.yml config/path/filename.yml
```

## 故障排除

### 转换失败
1. 检查YAML文件语法
2. 查看错误日志定位问题
3. 手动修复语法问题后重试
4. 使用在线YAML验证器

### JSON验证失败
1. 检查编码是否为UTF-8
2. 确认没有多余逗号
3. 检查引号匹配
4. 使用JSON格式化工具

### 游戏中加载失败
1. 确认JSON文件路径正确
2. 检查JSON语法有效性
3. 查看Godot控制台错误信息
4. 运行测试脚本验证

## 联系和支持

如有问题，请：
1. 查看本文档的故障排除部分
2. 检查转换工具的错误日志
3. 验证JSON文件格式
4. 运行游戏测试脚本确认功能正常