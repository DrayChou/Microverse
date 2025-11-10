extends RefCounted
class_name JSONLoader

# JSON 配置加载器
# 使用 Godot 4.4 内置的 JSON 解析器

class LoadResult:
	var success: bool = false
	var data: Dictionary = {}
	var error_message: String = ""

	func _init(p_success: bool = false, p_data: Dictionary = {}, p_error_message: String = ""):
		success = p_success
		data = p_data
		error_message = p_error_message

# 主要的配置加载方法
static func load_json_config(file_path: String) -> LoadResult:
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		return LoadResult.new(false, {}, "配置文件不存在: " + file_path)

	# 读取文件内容
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return LoadResult.new(false, {}, "无法打开配置文件: " + file_path)

	var json_content = file.get_as_text()
	file.close()

	if json_content.is_empty():
		return LoadResult.new(false, {}, "配置文件为空: " + file_path)

	# 使用 Godot 内置的 JSON 解析器
	var json = JSON.new()
	var parse_result = json.parse(json_content)

	if parse_result != OK:
		return LoadResult.new(false, {}, "JSON解析失败: " + file_path + " 错误: " + json.get_error_message())

	if not json.data is Dictionary:
		return LoadResult.new(false, {}, "配置文件根对象必须是字典: " + file_path)

	return LoadResult.new(true, json.data)

# 保存 JSON 配置
static func save_json_config(data: Dictionary, file_path: String) -> bool:
	var json_string = JSON.stringify(data, "\t")  # 使用制表符缩进，更易读

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("无法创建配置文件: ", file_path)
		return false

	file.store_string(json_string)
	file.close()
	return true

# 验证配置结构
static func validate_config(config: Dictionary, required_keys: Array[String] = []) -> LoadResult:
	for key in required_keys:
		if not config.has(key):
			return LoadResult.new(false, {}, "缺少必需的配置键: " + key)

	return LoadResult.new(true, config)

# 合并配置（用于默认值覆盖）
static func merge_configs(base: Dictionary, override: Dictionary) -> Dictionary:
	var result = base.duplicate(true)
	_merge_recursive(result, override)
	return result

static func _merge_recursive(target: Dictionary, source: Dictionary):
	for key in source:
		if source[key] is Dictionary and target.has(key) and target[key] is Dictionary:
			_merge_recursive(target[key], source[key])
		else:
			target[key] = source[key]