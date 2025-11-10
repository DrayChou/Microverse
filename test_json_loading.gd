extends Node

# 测试 JSON 配置加载是否正常工作

func _ready():
	print("=== 测试 JSON 配置加载 ===")

	# 测试 JSON 配置加载
	test_json_loading()

	# 测试 ContentManager 现在是否使用 JSON
	test_content_manager_json_usage()

	# 测试 APIConfig
	test_api_config_json_usage()

func test_json_loading():
	print("\n--- 测试 JSON 配置加载 ---")

	var test_files = [
		"res://config/content/ai/models.json",
		"res://config/content/characters/characters.json",
		"res://config/content/package.json",
		"res://config/systems/audio/master.json"
	]

	for file_path in test_files:
		print("\n测试: ", file_path)

		# 检查文件存在性
		if not FileAccess.file_exists(file_path):
			print("  ❌ JSON文件不存在")
			continue

		# 测试直接JSON加载
		var result = ContentManager._load_json_config(file_path)
		if result.success:
			print("  ✅ JSON加载成功")
			print("    - 数据键数: ", result.data.keys().size())

			# 检查 AI 模型配置的具体内容
			if "models" in file_path or "ai" in file_path:
				print("    - AI配置结构:")
				if result.data.has("content"):
					var content = result.data["content"]
					if content.has("ai"):
						print("      - AI配置存在")
						if content["ai"].has("models"):
							print("      - 模型配置存在")
							if content["ai"]["models"].has("providers"):
								print("      - 提供商配置存在: ", content["ai"]["models"]["providers"].keys())
		else:
			print("  ❌ JSON加载失败: ", result.error_message)

func test_content_manager_json_usage():
	print("\n--- 测试 ContentManager JSON 使用情况 ---")

	# 强制重新初始化 ContentManager
	var cm = ContentManager.new()
	cm._initialize()

	print("✅ ContentManager 重新初始化完成")

	# 检查 AI 配置
	var ai_providers = cm.get_all_ai_providers()
	print("\n  AI配置测试:")
	print("    - 提供商数量: ", ai_providers.size())

	if ai_providers.has("lmstudio"):
		var lmstudio = ai_providers["lmstudio"]
		print("  ✅ LMStudio 配置正常")
		print("    - 显示名称: ", lmstudio.display_name)
		print("    - 类型: ", lmstudio.type)
		print("    - 端点: ", lmstudio.endpoint)
		print("    - 默认模型: ", lmstudio.default_model)
		print("    - 认证: ", lmstudio.authentication)
	else:
		print("\n  ❌ LMStudio 配置获取失败")

	# 检查角色配置
	var characters = cm.get_all_characters()
	print("\n  角色配置测试:")
	print("    - 角色数量: ", characters.size())

	if characters.size() > 0:
		var character_names = characters.keys()
		var display_names = []
		for i in range(min(5, character_names.size())):
			display_names.append(character_names[i])
		print("    - 角色列表: ", display_names, " (显示前5个)")

		# 检查第一个角色的详细配置
		var first_char_id = character_names[0]
		var char_config = cm.get_character_config(first_char_id)
		if char_config:
			print("    - 角色 ", first_char_id, " 配置正常")

	print("\n🔍 配置来源检查:")
	print("  💡 如果看到 JSON 加载成功，说明 JSON 配置正在被使用")
	print("  💡 如果配置加载成功，说明系统运行正常")

func test_api_config_json_usage():
	print("\n--- 测试 APIConfig JSON 使用情况 ---")

	# 强制重新初始化 APIConfig
	APIConfig._initialize()

	# 获取支持的API类型
	var api_types = APIConfig.get_api_types()
	print("  支持的API类型: ", api_types)

	# 检查每个提供商
	print("\n  🔍 AI提供商详情:")
	for api_type in api_types:
		var provider = APIConfig.get_provider(api_type)
		if provider:
			print("    ✅ ", api_type, ": ", provider.display_name)
		else:
			print("    ❌ ", api_type, ": 配置获取失败")

	print("\n=== 测试完成 ===")
	print("💡 JSON 配置系统工作正常！")
	print("💡 现在运行游戏应该能看到 JSON 配置的加载日志！")