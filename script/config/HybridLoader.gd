extends RefCounted
class_name HybridLoader

# 混合配置加载器 - 优先使用 JSON，回退到 YAML
# 解决配置系统兼容性问题

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
static func load_config(file_path: String) -> LoadResult:
	# 首先尝试 JSON 版本
	var json_path = file_path.get_basename() + ".json"
	var json_result = JSONLoader.load_json_config(json_path)

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

# 检查文件类型可用性
static func check_file_availability(file_path: String) -> Dictionary:
	var json_path = file_path.get_basename() + ".json"
	var yaml_path = file_path

	return {
		"json_exists": FileAccess.file_exists(json_path),
		"yaml_exists": FileAccess.file_exists(yaml_path),
		"json_path": json_path,
		"yaml_path": yaml_path,
		"preferred": json_path  # 优先使用 JSON
	}
}

# 获取推荐的文件路径
static func get_preferred_path(file_path: String) -> String:
	var availability = check_file_availability(file_path)
	if availability.json_exists:
		return availability.json_path
	else:
		return availability.yaml_path