# 配置系统测试说明

## 🎯 快速测试（推荐）

### 在 Godot 编辑器中运行：

1. **打开项目**
   ```
   打开 Godot 编辑器 → 打开项目 → 选择 /Users/dray/Code/Microverse 文件夹
   ```

2. **创建测试场景**
   - 创建新场景（`Node` 节点）
   - 附加 `test_configs.gd` 脚本
   - 保存场景为 `TestScene.tscn`

3. **运行测试**
   - 按 F5 运行场景
   - 查看编辑器底部的控制台输出

## 📋 预期的测试结果

如果配置系统正常工作，你应该看到：

```
=== 配置系统快速测试 ===

--- 测试YAML加载 ---
✅ AI配置加载成功
  提供商数量: X
  - Ollama
  - LMStudio
  - OpenAI
  ...
✅ 物理配置加载成功
  物理配置键: [base_speed, acceleration, ...]

--- 测试ContentManager ---
✅ ContentManager初始化成功
  AI提供商数量: X
  物理配置键数量: X
  - base_speed: 100.0

--- 测试APIConfig集成 ---
  支持的API类型: X
  ✅ LMStudio配置正常
  - 显示名称: LMStudio (本地)

=== 测试完成 ===

💡 如果所有测试都显示 ✅，说明配置系统正常工作！
```

## 🔧 如果遇到问题

### 常见错误和解决方法：

1. **"❌ ContentManager初始化失败"**
   - 检查 `script/config/ContentManager.gd` 是否有语法错误

2. **"❌ AI配置加载失败"**
   - 检查 `config/content/ai/models.yml` 文件路径和语法

3. **"❌ 物理配置加载失败"**
   - 检查 `config/systems/physics/movement.yml` 文件

4. **解析错误**
   - 检查控制台的具体错误信息
   - 确保所有 YAML 文件缩进使用2个空格

## 📞 获取帮助

如果测试失败，请：
1. 复制完整的控制台输出
2. 检查 Godot 编辑器底部的错误面板
3. 确认所有文件都已正确保存

## 🎉 成功标准

✅ 所有测试项都显示 ✅ 或正数值
✅ 没有红色的错误信息
✅ 能看到 AI 提供商列表
✅ 能读取到物理配置的 base_speed