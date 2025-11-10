extends Node
class_name JSONContentManager

# JSON 版本的配置管理器
# 使用 Godot 4.4 内置的 JSON 解析器

# 单例实例
static var instance: JSONContentManager

# 配置文件路径常量
const CONFIG_ROOT = "res://config/"
const CONTENT_ROOT = CONFIG_ROOT + "content/"
const SYSTEMS_ROOT = CONFIG_ROOT + "systems/"
const RUNTIME_ROOT = CONFIG_ROOT + "runtime/"
const UI_ROOT = CONFIG_ROOT + "ui/"

# 内容配置文件
const PACKAGE_CONFIG_FILE = CONTENT_ROOT + "package.json"
const AI_MODELS_CONFIG_FILE = CONTENT_ROOT + "ai/models.json"
const CHARACTERS_CONFIG_FILE = CONTENT_ROOT + "characters/characters.json"

# 系统配置文件
const PHYSICS_CONFIG_FILE = SYSTEMS_ROOT + "physics/movement.json"
const AUDIO_CONFIG_FILE = SYSTEMS_ROOT + "audio/master.json"

# 运行时配置文件
const DEBUG_CONFIG_FILE = RUNTIME_ROOT + "debug/development.json"

# 配置数据
var package_configs: Dictionary = {}
var ai_model_configs: Dictionary = {}
var character_configs: Dictionary = {}
var physics_configs: Dictionary = {}
var audio_configs: Dictionary = {}
var debug_configs: Dictionary = {}

var _initialized: bool = false

# 获取单例实例
static func get_instance() -> JSONContentManager:
	if instance == null:
		instance = JSONContentManager.new()
		instance._initialize()
	return instance

# 初始化配置管理器
func _initialize():
	if _initialized:
		return

	print("[JSONContentManager] 开始加载配置...")
	load_all_configs()
	_initialized = true
	print("[JSONContentManager] 配置初始化完成")

# 加载所有配置
func load_all_configs():
	# 加载内容配置
	_load_package_config()
	_load_ai_model_configs()
	_load_character_configs()

	# 加载系统配置
	_load_physics_configs()
	_load_audio_configs()

	# 加载运行时配置
	_load_debug_configs()

# 内容配置加载
func _load_package_config():
	var result = JSONLoader.load_json_config(PACKAGE_CONFIG_FILE)
	if result.success:
		package_configs = result.data.get("package", {})
		print("[JSONContentManager] 已加载包配置")
	else:
		print("[JSONContentManager错误] 包配置加载失败: ", result.error_message)
		package_configs = {}

func _load_ai_model_configs():
	var result = JSONLoader.load_json_config(AI_MODELS_CONFIG_FILE)
	if result.success:
		ai_model_configs = result.data.get("content", {}).get("ai", {}).get("models", {})
		print("[JSONContentManager] 已加载AI模型配置")
	else:
		print("[JSONContentManager错误] AI模型配置加载失败: ", result.error_message)
		ai_model_configs = {}

func _load_character_configs():
	var result = JSONLoader.load_json_config(CHARACTERS_CONFIG_FILE)
	if result.success:
		character_configs = result.data.get("content", {}).get("characters", {})
		print("[JSONContentManager] 已加载 ", character_configs.size(), " 个角色配置")
	else:
		print("[JSONContentManager错误] 角色配置加载失败: ", result.error_message)
		character_configs = {}

# 系统配置加载
func _load_physics_configs():
	var result = JSONLoader.load_json_config(PHYSICS_CONFIG_FILE)
	if result.success:
		physics_configs = result.data.get("systems", {}).get("physics", {})
		print("[JSONContentManager] 已加载物理系统配置")
	else:
		print("[JSONContentManager错误] 物理系统配置加载失败: ", result.error_message)
		physics_configs = {}

func _load_audio_configs():
	var result = JSONLoader.load_json_config(AUDIO_CONFIG_FILE)
	if result.success:
		audio_configs = result.data.get("systems", {}).get("audio", {})
		print("[JSONContentManager] 已加载音频系统配置")
	else:
		print("[JSONContentManager错误] 音频系统配置加载失败: ", result.error_message)
		audio_configs = {}

# 运行时配置加载
func _load_debug_configs():
	var result = JSONLoader.load_json_config(DEBUG_CONFIG_FILE)
	if result.success:
		debug_configs = result.data.get("runtime", {}).get("debug", {})
		print("[JSONContentManager] 已加载调试配置")
	else:
		print("[JSONContentManager错误] 调试配置加载失败: ", result.error_message)
		debug_configs = {}

# 配置访问方法
func get_package_config() -> Dictionary:
	return package_configs

func get_all_ai_providers() -> Dictionary:
	return ai_model_configs.get("providers", {})

func get_all_character_names() -> Array[String]:
	var names: Array[String] = []
	for character_id in character_configs.keys():
		names.append(character_id)
	return names

func get_character_config(character_name: String) -> Dictionary:
	return character_configs.get(character_name, {})

func get_physics_config() -> Dictionary:
	return physics_configs

func get_audio_config() -> Dictionary:
	return audio_configs

func get_debug_config() -> Dictionary:
	return debug_configs

# 通用配置获取方法
func get_config(section: String, key: String, default_value = null):
	match section:
		"package":
			return package_configs.get(key, default_value)
		"ai_providers":
			return get_all_ai_providers().get(key, default_value)
		"characters":
			return character_configs.get(key, default_value)
		"physics":
			return physics_configs.get(key, default_value)
		"audio":
			return audio_configs.get(key, default_value)
		"debug":
			return debug_configs.get(key, default_value)
		_:
			return default_value

# 重新加载配置
func reload_config(config_type: String):
	match config_type:
		"package":
			_load_package_config()
		"ai":
			_load_ai_model_configs()
		"characters":
			_load_character_configs()
		"physics":
			_load_physics_configs()
		"audio":
			_load_audio_configs()
		"debug":
			_load_debug_configs()
		"all":
			load_all_configs()