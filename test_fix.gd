extends SceneTree

# 简单的修复验证测试

func _init():
	print("=== ContentManager 修复验证测试 ===")

	# 测试内联混合加载功能
	test_hybrid_loading()

	# 完成测试
	quit()

func test_hybrid_loading():
	print("\n1. 测试内联混合加载系统...")

	# 测试 JSON 加载
	print("\n测试 JSON 配置加载:")
	var json_result = ContentManager._load_json_config("res://config/content/ai/models.json")
	if json_result.success:
		print("✓ JSON 加载成功")
		print("  数据键: ", json_result.data.keys())
	else:
		print("✗ JSON 加载失败: ", json_result.error_message)

	# 测试混合加载
	print("\n测试混合加载系统:")
	var hybrid_result = ContentManager._load_config_hybrid("res://config/content/ai/models.yml")
	if hybrid_result.success:
		print("✓ 混合加载成功 (来源: ", hybrid_result.source_type, ")")
		print("  加载的数据键: ", hybrid_result.data.keys())
	else:
		print("✗ 混合加载失败: ", hybrid_result.error_message)

	print("\n2. 验证配置文件存在性:")
	var test_files = [
		"res://config/content/ai/models.json",
		"res://config/content/characters/characters.json",
		"res://config/systems/audio/master.json",
		"res://config/ui/ui_config.json"
	]

	for file_path in test_files:
		if FileAccess.file_exists(file_path):
			print("✓ ", file_path)
		else:
			print("✗ ", file_path, " (文件不存在)")

	print("\n3. 测试完成!")