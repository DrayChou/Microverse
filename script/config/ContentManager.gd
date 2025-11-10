extends Node
class_name ContentManager

# 内容管理器 - 重新整理的配置目录结构
# 负责加载和管理所有配置文件（优先JSON，回退YAML）

# 单例实例
static var instance: ContentManager = null

# 内容配置数据 (content/) - 游戏内容和资产
var package_info: Dictionary = {}
var character_configs: Dictionary = {}
var character_personalities: Dictionary = {}
var ai_model_configs: Dictionary = {}
var background_story_configs: Dictionary = {}
var story_configs: Dictionary = {}

# 系统配置数据 (systems/) - 系统和引擎配置
var physics_configs: Dictionary = {}
var audio_configs: Dictionary = {}
var graphics_configs: Dictionary = {}
var input_configs: Dictionary = {}
var ui_configs: Dictionary = {}
var camera_configs: Dictionary = {}
var animation_system_configs: Dictionary = {}
var dialogue_system_configs: Dictionary = {}
var gameplay_system_configs: Dictionary = {}
var scenes_system_configs: Dictionary = {}
var scene_paths_system_configs: Dictionary = {}
var locations_system_configs: Dictionary = {}

# 运行时配置数据 (runtime/)
var storage_configs: Dictionary = {}
var save_configs: Dictionary = {}
var network_configs: Dictionary = {}
var debug_configs: Dictionary = {}
var game_settings_configs: Dictionary = {}

# UI配置数据 (ui/)
var ui_camera_configs: Dictionary = {}
var ui_game_settings_configs: Dictionary = {}
var ui_ui_configs: Dictionary = {}

# 配置文件路径常量
const CONFIG_ROOT = "res://config/"

# 内容配置文件 (content/)
const CONTENT_ROOT = CONFIG_ROOT + "content/"
const PACKAGE_CONFIG_FILE = CONTENT_ROOT + "package.yml"
const CHARACTERS_CONFIG_FILE = CONTENT_ROOT + "characters/characters.yml"
const PERSONALITIES_CONFIG_FILE = CONTENT_ROOT + "characters/personalities.yml"
const AI_MODELS_CONFIG_FILE = CONTENT_ROOT + "ai/models.yml"
const BACKGROUND_STORIES_CONFIG_FILE = CONTENT_ROOT + "background_stories.yml"
const STORIES_CONFIG_FILE = CONTENT_ROOT + "stories/main.yml"

# 系统配置文件 (systems/)
const SYSTEMS_ROOT = CONFIG_ROOT + "systems/"
const PHYSICS_CONFIG_FILE = SYSTEMS_ROOT + "physics/movement.yml"
const AUDIO_CONFIG_FILE = SYSTEMS_ROOT + "audio/master.yml"
const GRAPHICS_CONFIG_FILE = SYSTEMS_ROOT + "graphics.yml"
const INPUT_CONFIG_FILE = SYSTEMS_ROOT + "input/controls.yml"
const UI_CONFIG_FILE = SYSTEMS_ROOT + "ui/layout.yml"
const CAMERA_CONFIG_FILE = SYSTEMS_ROOT + "camera/movement.yml"
const ANIMATION_SYSTEM_CONFIG_FILE = SYSTEMS_ROOT + "animations/character.yml"
const DIALOGUE_SYSTEM_CONFIG_FILE = SYSTEMS_ROOT + "dialogue/system.yml"
const GAMEPLAY_SYSTEM_CONFIG_FILE = SYSTEMS_ROOT + "gameplay/movement.yml"
const SCENES_SYSTEM_CONFIG_FILE = SYSTEMS_ROOT + "scenes/scenes.yml"
const SCENE_PATHS_SYSTEM_CONFIG_FILE = SYSTEMS_ROOT + "scenes/scene_paths.yml"
const LOCATIONS_SYSTEM_CONFIG_FILE = SYSTEMS_ROOT + "scenes/locations.yml"

# 运行时配置文件 (runtime/)
const RUNTIME_ROOT = CONFIG_ROOT + "runtime/"
const STORAGE_CONFIG_FILE = RUNTIME_ROOT + "storage/paths.yml"
const SAVE_CONFIG_FILE = RUNTIME_ROOT + "save/system.yml"
const NETWORK_CONFIG_FILE = RUNTIME_ROOT + "network/client.yml"
const DEBUG_CONFIG_FILE = RUNTIME_ROOT + "debug/development.yml"
const GAME_SETTINGS_CONFIG_FILE = RUNTIME_ROOT + "game_settings.yml"

# UI配置文件 (ui/)
const UI_ROOT = CONFIG_ROOT + "ui/"
const UI_CAMERA_CONFIG_FILE = UI_ROOT + "camera_config.yml"
const UI_GAME_SETTINGS_CONFIG_FILE = UI_ROOT + "game_settings.yml"
const UI_UI_CONFIG_FILE = UI_ROOT + "ui_config.yml"

# 是否已初始化
var _initialized: bool = false

# 获取单例实例
static func get_instance() -> ContentManager:
	if instance == null:
		instance = ContentManager.new()
		instance._initialize()
	return instance

# 初始化配置管理器
func _initialize():
	if _initialized:
		return

	print("[ContentManager] 开始加载配置...")

	# 加载内容配置 (content/)
	_load_package_config()
	_load_character_configs()
	_load_character_personalities()
	_load_ai_model_configs()
	_load_background_story_configs()
	_load_story_configs()

	# 加载系统配置 (systems/)
	_load_physics_configs()
	_load_audio_configs()
	_load_graphics_configs()
	_load_input_configs()
	_load_ui_configs()
	_load_camera_configs()
	_load_animation_system_configs()
	_load_dialogue_system_configs()
	_load_gameplay_system_configs()
	_load_scenes_system_configs()
	_load_scene_paths_system_configs()
	_load_locations_system_configs()

	# 加载运行时配置 (runtime/)
	_load_storage_configs()
	_load_save_configs()
	_load_network_configs()
	_load_debug_configs()
	_load_game_settings_configs()

	# 加载UI配置
	# _load_ui_camera_configs()
	# _load_ui_game_settings_configs()
	# _load_ui_ui_configs()

	_initialized = true
	print("[ContentManager] 配置初始化完成")

# === 内容配置加载方法 (content/) ===

func _load_package_config():
	var result = _load_config_hybrid(PACKAGE_CONFIG_FILE)
	if result.success:
		if result.source_type == "json":
			package_info = result.data.get("package", {})
		else:
			package_info = result.data.get("content", {}).get("package", {})
		print("[ContentManager] 已加载包配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 包配置加载失败: ", result.error_message)
		package_info = {}

func _load_character_configs():
	var result = _load_config_hybrid(CHARACTERS_CONFIG_FILE)
	if result.success:
		if result.source_type == "json":
			character_configs = result.data.get("content", {}).get("characters", {})
		else:
			character_configs = result.data.get("content", {}).get("characters", {})
		print("[ContentManager] 已加载 ", character_configs.size(), " 个角色配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 角色配置加载失败: ", result.error_message)
		character_configs = {}

func _load_character_personalities():
	var result = _load_config_hybrid(PERSONALITIES_CONFIG_FILE)
	if result.success:
		character_personalities = result.data.get("content", {}).get("characters", {}).get("personalities", {})
		print("[ContentManager] 已加载角色性格配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 角色性格配置加载失败: ", result.error_message)
		character_personalities = {}

func _load_ai_model_configs():
	var result = _load_config_hybrid(AI_MODELS_CONFIG_FILE)
	if result.success:
		if result.source_type == "json":
			ai_model_configs = result.data.get("content", {}).get("ai", {}).get("models", {})
		else:
			ai_model_configs = result.data.get("content", {}).get("ai", {}).get("models", {})
		print("[ContentManager] 已加载AI模型配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] AI模型配置加载失败: ", result.error_message)
		ai_model_configs = {}

func _load_background_story_configs():
	var result = _load_config_hybrid(BACKGROUND_STORIES_CONFIG_FILE)
	if result.success:
		background_story_configs = result.data.get("background_stories", {})
		print("[ContentManager] 已加载 ", background_story_configs.size(), " 个背景故事配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 背景故事配置加载失败: ", result.error_message)
		background_story_configs = {}

func _load_story_configs():
	var result = _load_config_hybrid(STORIES_CONFIG_FILE)
	if result.success:
		if result.source_type == "json":
			story_configs = result.data.get("content", {}).get("stories", {})
		else:
			story_configs = result.data.get("content", {}).get("stories", {})
		print("[ContentManager] 已加载 ", story_configs.size(), " 个故事线配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 故事线配置加载失败: ", result.error_message)
		story_configs = {}

# === 系统配置加载方法 (systems/) ===

func _load_physics_configs():
	var result = _load_config_hybrid(PHYSICS_CONFIG_FILE)
	if result.success:
		physics_configs = result.data.get("systems", {}).get("physics", {})
		print("[ContentManager] 已加载物理系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 物理系统配置加载失败: ", result.error_message)
		physics_configs = {}

func _load_audio_configs():
	var result = _load_config_hybrid(AUDIO_CONFIG_FILE)
	if result.success:
		audio_configs = result.data.get("systems", {}).get("audio", {})
		print("[ContentManager] 已加载音频系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 音频系统配置加载失败: ", result.error_message)
		audio_configs = {}

func _load_graphics_configs():
	var result = _load_config_hybrid(GRAPHICS_CONFIG_FILE)
	if result.success:
		graphics_configs = result.data.get("systems", {}).get("graphics", {})
		print("[ContentManager] 已加载图形系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 图形系统配置加载失败: ", result.error_message)
		graphics_configs = {}

func _load_input_configs():
	var result = _load_config_hybrid(INPUT_CONFIG_FILE)
	if result.success:
		input_configs = result.data.get("systems", {}).get("input", {})
		print("[ContentManager] 已加载输入系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 输入系统配置加载失败: ", result.error_message)
		input_configs = {}

func _load_ui_configs():
	var result = _load_config_hybrid(UI_CONFIG_FILE)
	if result.success:
		ui_configs = result.data.get("systems", {}).get("ui", {})
		print("[ContentManager] 已加载UI系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] UI系统配置加载失败: ", result.error_message)
		ui_configs = {}

func _load_camera_configs():
	var result = _load_config_hybrid(CAMERA_CONFIG_FILE)
	if result.success:
		camera_configs = result.data.get("systems", {}).get("camera", {})
		print("[ContentManager] 已加载摄像机系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 摄像机系统配置加载失败: ", result.error_message)
		camera_configs = {}

func _load_animation_system_configs():
	var result = _load_config_hybrid(ANIMATION_SYSTEM_CONFIG_FILE)
	if result.success:
		animation_system_configs = result.data.get("systems", {}).get("animations", {})
		print("[ContentManager] 已加载动画系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 动画系统配置加载失败: ", result.error_message)
		animation_system_configs = {}

func _load_dialogue_system_configs():
	var result = _load_config_hybrid(DIALOGUE_SYSTEM_CONFIG_FILE)
	if result.success:
		dialogue_system_configs = result.data.get("content", {}).get("dialogue", {})
		print("[ContentManager] 已加载对话系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 对话系统配置加载失败: ", result.error_message)
		dialogue_system_configs = {}

func _load_gameplay_system_configs():
	var result = _load_config_hybrid(GAMEPLAY_SYSTEM_CONFIG_FILE)
	if result.success:
		gameplay_system_configs = result.data.get("content", {}).get("gameplay", {})
		print("[ContentManager] 已加载游戏玩法系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 游戏玩法系统配置加载失败: ", result.error_message)
		gameplay_system_configs = {}

func _load_scenes_system_configs():
	var result = _load_config_hybrid(SCENES_SYSTEM_CONFIG_FILE)
	if result.success:
		scenes_system_configs = result.data.get("content", {}).get("scenes", {})
		print("[ContentManager] 已加载场景系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 场景系统配置加载失败: ", result.error_message)
		scenes_system_configs = {}

func _load_scene_paths_system_configs():
	var result = _load_config_hybrid(SCENE_PATHS_SYSTEM_CONFIG_FILE)
	if result.success:
		scene_paths_system_configs = result.data.get("content", {}).get("scenes", {}).get("paths", {})
		print("[ContentManager] 已加载场景路径系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 场景路径系统配置加载失败: ", result.error_message)
		scene_paths_system_configs = {}

func _load_locations_system_configs():
	var result = _load_config_hybrid(LOCATIONS_SYSTEM_CONFIG_FILE)
	if result.success:
		locations_system_configs = result.data.get("systems", {}).get("scenes", {}).get("locations", {})
		print("[ContentManager] 已加载地点系统配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 地点系统配置加载失败: ", result.error_message)
		locations_system_configs = {}

# === 运行时配置加载方法 (runtime/) ===

func _load_storage_configs():
	var result = _load_config_hybrid(STORAGE_CONFIG_FILE)
	if result.success:
		storage_configs = result.data.get("runtime", {}).get("storage", {})
		print("[ContentManager] 已加载存储配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 存储配置加载失败: ", result.error_message)
		storage_configs = {}

func _load_save_configs():
	var result = _load_config_hybrid(SAVE_CONFIG_FILE)
	if result.success:
		save_configs = result.data.get("runtime", {}).get("save", {})
		print("[ContentManager] 已加载存档配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 存档配置加载失败: ", result.error_message)
		save_configs = {}

func _load_network_configs():
	var result = _load_config_hybrid(NETWORK_CONFIG_FILE)
	if result.success:
		network_configs = result.data.get("runtime", {}).get("network", {})
		print("[ContentManager] 已加载网络配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 网络配置加载失败: ", result.error_message)
		network_configs = {}

func _load_debug_configs():
	var result = _load_config_hybrid(DEBUG_CONFIG_FILE)
	if result.success:
		debug_configs = result.data.get("runtime", {}).get("debug", {})
		print("[ContentManager] 已加载调试配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 调试配置加载失败: ", result.error_message)
		debug_configs = {}

func _load_game_settings_configs():
	var result = _load_config_hybrid(GAME_SETTINGS_CONFIG_FILE)
	if result.success:
		game_settings_configs = result.data.get("game_settings", {})
		print("[ContentManager] 已加载游戏设置配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] 游戏设置配置加载失败: ", result.error_message)
		game_settings_configs = {}

# === UI配置加载方法 (ui/) ===

func _load_ui_camera_configs():
	var result = _load_config_hybrid(UI_CAMERA_CONFIG_FILE)
	if result.success:
		ui_camera_configs = result.data.get("camera_config", {})
		print("[ContentManager] 已加载UI摄像机配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] UI摄像机配置加载失败: ", result.error_message)
		ui_camera_configs = {}

func _load_ui_game_settings_configs():
	var result = _load_config_hybrid(UI_GAME_SETTINGS_CONFIG_FILE)
	if result.success:
		ui_game_settings_configs = result.data.get("game_settings", {})
		print("[ContentManager] 已加载UI游戏设置配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] UI游戏设置配置加载失败: ", result.error_message)
		ui_game_settings_configs = {}

func _load_ui_ui_configs():
	var result = _load_config_hybrid(UI_UI_CONFIG_FILE)
	if result.success:
		ui_ui_configs = result.data.get("ui_config", {})
		print("[ContentManager] 已加载UI配置 (", result.source_type.to_upper(), ")")
	else:
		print("[ContentManager错误] UI配置加载失败: ", result.error_message)
		ui_ui_configs = {}

# === 配置访问方法 ===

func get_package_info() -> Dictionary:
	return package_info

func get_character_config(character_name: String) -> Dictionary:
	return character_configs.get(character_name, {})

func get_all_character_names() -> Array[String]:
	var names: Array[String] = []
	for key in character_configs.keys():
		if key is String:
			names.append(key)
	return names

func get_character_personality(character_name: String) -> Dictionary:
	return character_personalities.get(character_name, {})

func get_full_character_info(character_name: String) -> Dictionary:
	var character = get_character_config(character_name)
	var personality = get_character_personality(character_name)
	return {
		"character": character,
		"personality": personality
	}

func get_all_ai_providers() -> Dictionary:
	return ai_model_configs.get("providers", {})

func get_dialogue_config() -> Dictionary:
	return dialogue_system_configs

func get_story_config(story_name: String) -> Dictionary:
	return story_configs.get(story_name, {})

func get_physics_config() -> Dictionary:
	return physics_configs

func get_audio_config() -> Dictionary:
	return audio_configs

func get_graphics_config() -> Dictionary:
	return graphics_configs

func get_input_config() -> Dictionary:
	return input_configs

func get_ui_config_section(section_path: String = "") -> Dictionary:
	return _get_nested_config(ui_configs, section_path)

func get_camera_config() -> Dictionary:
	return camera_configs

func get_animation_config() -> Dictionary:
	return animation_system_configs

func get_gameplay_config() -> Dictionary:
	return gameplay_system_configs

func get_scenes_config() -> Dictionary:
	return scenes_system_configs

func get_scene_paths_config() -> Dictionary:
	return scene_paths_system_configs

func get_background_config(location_name: String) -> Dictionary:
	return locations_system_configs.get(location_name, {})

func get_storage_config() -> Dictionary:
	return storage_configs

func get_save_config() -> Dictionary:
	return save_configs

func get_network_config() -> Dictionary:
	return network_configs

func get_debug_config() -> Dictionary:
	return debug_configs

func get_game_settings_config() -> Dictionary:
	return game_settings_configs

# 工具方法
func _get_nested_config(config: Dictionary, path: String) -> Dictionary:
	if path.is_empty():
		return config

	var parts = path.split("/")
	var current = config
	for part in parts:
		if current.has(part):
			current = current[part]
		else:
			return {}
	return current

func get_config(config_type: String, section_path: String = "") -> Dictionary:
	match config_type:
		"package":
			return _get_nested_config(package_info, section_path)
		"characters":
			return _get_nested_config(character_configs, section_path)
		"ai_models":
			return _get_nested_config(ai_model_configs, section_path)
		"background_stories":
			return _get_nested_config(background_story_configs, section_path)
		"stories":
			return _get_nested_config(story_configs, section_path)
		"physics":
			return _get_nested_config(physics_configs, section_path)
		"audio":
			return _get_nested_config(audio_configs, section_path)
		"graphics":
			return _get_nested_config(graphics_configs, section_path)
		"input":
			return _get_nested_config(input_configs, section_path)
		"ui":
			return _get_nested_config(ui_configs, section_path)
		"camera":
			return _get_nested_config(camera_configs, section_path)
		"storage":
			return _get_nested_config(storage_configs, section_path)
		"save":
			return _get_nested_config(save_configs, section_path)
		"network":
			return _get_nested_config(network_configs, section_path)
		"debug":
			return _get_nested_config(debug_configs, section_path)
		"game_settings":
			return _get_nested_config(game_settings_configs, section_path)
		_:
			print("[ContentManager警告] 未知的配置类型: ", config_type)
			return {}

# === 混合配置加载器 (内联实现) ===
# 优先使用 JSON，回退到 YAML

class LoadResult:
	var success: bool = false
	var data: Dictionary = {}
	var source_type: String = ""  # "json" 或 "yaml"
	var error_message: String = ""

	func _init(p_success: bool = false, p_data: Dictionary = {}, p_source_type: String = "", p_error_message: String = ""):
		success = p_success
		data = p_data
		source_type = p_source_type
		error_message = p_error_message

# 主要的混合加载方法
static func _load_config_hybrid(file_path: String) -> LoadResult:
	# 首先尝试 JSON 版本
	var json_path = file_path.get_basename() + ".json"
	var json_result = _load_json_config(json_path)

	if json_result.success:
		return LoadResult.new(true, json_result.data, "json", "")

	# JSON 不存在或失败，尝试 YAML 版本
	var yaml_result = ConfigLoader.load_yaml_config(file_path)
	if yaml_result.success:
		return LoadResult.new(true, yaml_result.data, "yaml", "")

	# 两者都失败
	var json_error = "JSON: " + json_result.error_message if not FileAccess.file_exists(json_path) else ""
	var yaml_error = "YAML: " + yaml_result.error_message
	return LoadResult.new(false, {}, "", json_error + " | " + yaml_error)

# JSON 加载方法
static func _load_json_config(file_path: String) -> LoadResult:
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		return LoadResult.new(false, {}, "", "配置文件不存在: " + file_path)

	# 读取文件内容
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return LoadResult.new(false, {}, "", "无法打开配置文件: " + file_path)

	var json_content = file.get_as_text()
	file.close()

	if json_content.is_empty():
		return LoadResult.new(false, {}, "", "配置文件为空: " + file_path)

	# 使用 Godot 内置的 JSON 解析器
	var json = JSON.new()
	var parse_result = json.parse(json_content)

	if parse_result != OK:
		return LoadResult.new(false, {}, "", "JSON解析失败: " + file_path + " 错误: " + json.get_error_message())

	if not json.data is Dictionary:
		return LoadResult.new(false, {}, "", "配置文件根对象必须是字典: " + file_path)

	return LoadResult.new(true, json.data)

func get_config_stats() -> Dictionary:
	return {
		"content配置": package_info.size() + character_configs.size() + character_personalities.size() + ai_model_configs.size() + background_story_configs.size() + story_configs.size(),
		"systems配置": physics_configs.size() + audio_configs.size() + graphics_configs.size() + input_configs.size() + ui_configs.size() + camera_configs.size(),
	"runtime配置": storage_configs.size() + save_configs.size() + network_configs.size() + debug_configs.size() + game_settings_configs.size(),
		"ui配置": ui_camera_configs.size() + ui_ui_configs.size()
	}
