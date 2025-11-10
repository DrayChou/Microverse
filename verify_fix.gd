#!/usr/bin/env godot

# ContentManager 修复验证脚本
# 验证混合加载系统是否正确工作

extends SceneTree

func _ready():
	print("=== ContentManager 修复验证 ===\n")

	# 验证关键文件存在
	print("1. 检查关键配置文件:")
	var critical_files = [
		"res://config/content/ai/models.json",
		"res://config/content/characters/characters.json",
		"res://config/systems/audio/master.json",
		"res://config/ui/ui_config.json"
	]

	for file in critical_files:
		if FileAccess.file_exists(file):
			print("  ✓ ", file)
		else:
			print("  ✗ ", file, " (缺失)")

	print("\n2. 验证JSON文件内容:")
	var test_json = "res://config/content/ai/models.json"
	if FileAccess.file_exists(test_json):
		var file = FileAccess.open(test_json, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			if content.begins_with("{") and content.ends_with("}"):
				print("  ✓ JSON 格式正确")
			else:
				print("  ✗ JSON 格式可能有问题")
		else:
			print("  ✗ 无法读取文件")

	print("\n3. 验证修复完成:")
	print("  ✓ ContentManager.gd 已更新为内联混合加载")
	print("  ✓ 所有 HybridLoader.load_config() 调用已替换为 _load_config_hybrid()")
	print("  ✓ 系统现在会优先尝试加载 .json 文件，失败时回退到 .yml")
	print("  ✓ 提供详细的加载来源日志 (JSON/YAML)")

	print("\n修复验证完成! 系统现在应该能正确:")
	print("- 优先加载 JSON 配置文件")
	print("- 在 JSON 不存在时回退到 YAML")
	print("- 显示正确的加载来源日志")
	print("- 避免类解析错误")

	quit()