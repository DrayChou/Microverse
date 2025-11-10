extends RefCounted
class_name ConfigLoader

# 配置加载错误类型
enum ErrorType {
	FILE_NOT_FOUND,
	PARSE_ERROR,
	VALIDATION_ERROR,
	UNKNOWN_ERROR
}

# 配置加载结果
class LoadResult:
	var success: bool = false
	var data: Dictionary = {}
	var error_type: ErrorType = ErrorType.UNKNOWN_ERROR
	var error_message: String = ""

	func _init(p_success: bool = false, p_data: Dictionary = {}, p_error_type: ErrorType = ErrorType.UNKNOWN_ERROR, p_error_message: String = ""):
		success = p_success
		data = p_data
		error_type = p_error_type
		error_message = p_error_message

# YAML解析器类
class YAMLParser:
	# 简单的YAML解析器实现
	# 注意：这是一个基础实现，未来可以替换为更完整的YAML库

	static func parse(yaml_content: String) -> LoadResult:
		if yaml_content.is_empty():
			return LoadResult.new(false, {}, ErrorType.VALIDATION_ERROR, "YAML内容为空")

		var result_data = {}
		var lines = yaml_content.split("\n")
		var context_stack = [result_data]  # 用于跟踪嵌套上下文
		var indent_stack = [-1]  # 用于跟踪缩进级别

		for line_num in range(lines.size()):
			var original_line = lines[line_num]
			var line = original_line.strip_edges(true, false)  # 只去掉右边空白，保留左边缩进

			# 跳过空行和注释
			var stripped_line = line.strip_edges()
			if stripped_line.is_empty() or stripped_line.begins_with("#"):
				continue

			# 计算当前行的缩进
			var current_indent = 0
			for char in line:
				if char == " ":
					current_indent += 1
				elif char == "\t":
					current_indent += 4  # 假设tab为4个空格
				else:
					break

			# 获取实际内容（去掉缩进）
			var content = line.strip_edges()

			# 处理键值对
			var colon_index = content.find(":")
			if colon_index == -1:
				return LoadResult.new(false, {}, ErrorType.PARSE_ERROR, "第%d行：缺少冒号 - %s" % [line_num + 1, content])

			var key = content.substr(0, colon_index).strip_edges()
			var value_part = content.substr(colon_index + 1).strip_edges()

			# 确定当前上下文（根据缩进）
			while indent_stack.size() > 1 and indent_stack[-1] >= current_indent:
				context_stack.pop_back()
				indent_stack.pop_back()

			var current_context = context_stack[-1]

			if value_part.is_empty():
				# 检查下一行是否是数组项
				if line_num + 1 < lines.size():
					var next_line = lines[line_num + 1].strip_edges()
					if next_line.begins_with("-"):
						# 这是一个数组（数组项在下一行）
						var array_data = []
						line_num += 1

						# 读取所有数组项
						while line_num < lines.size():
							var array_line_original = lines[line_num]
							var array_line_stripped = array_line_original.strip_edges()

							if array_line_stripped.is_empty() or array_line_stripped.begins_with("#"):
								line_num += 1
								continue

							# 检查是否还是数组项
							if array_line_stripped.begins_with("-"):
								var item_content = array_line_stripped.substr(1).strip_edges()
								if item_content.is_empty():
									# 这可能是一个对象数组的开始
									var obj_result = YAMLParser.parse_object_array_item(lines, line_num, current_indent + 2)
									array_data.append(obj_result.object)
									line_num = obj_result.end_line
								else:
									# 简单数组项
									array_data.append(parse_simple_value(item_content))
								line_num += 1
							else:
								# 数组结束
								line_num -= 1
								break

						current_context[key] = array_data
					else:
						# 这是一个嵌套对象
						var new_object = {}
						current_context[key] = new_object
						context_stack.append(new_object)
						indent_stack.append(current_indent)
				else:
					# 这是一个嵌套对象（文件末尾）
					var new_object = {}
					current_context[key] = new_object
					context_stack.append(new_object)
					indent_stack.append(current_indent)
			elif value_part.begins_with("|"):
				# 这是一个多行字符串
				var multiline_content = []
				line_num += 1
				while line_num < lines.size():
					var next_line_original = lines[line_num]
					var next_line_stripped = next_line_original.strip_edges()

					if next_line_stripped.is_empty():
						line_num += 1
						continue

					# 计算下一行的缩进
					var next_indent = 0
					for char in next_line_original:
						if char == " ":
							next_indent += 1
						elif char == "\t":
							next_indent += 4
						else:
							break

					# 如果缩进回到当前级别或更少，停止读取多行字符串
					if next_indent <= current_indent:
						line_num -= 1  # 回退一行
						break

					# 添加多行内容（保持原始缩进）
					multiline_content.append(next_line_original)
					line_num += 1

				# 合并多行内容
				current_context[key] = "".join(multiline_content)
			elif value_part.begins_with("-"):
				# 这是一个数组项的开始
				var array_data = []
				# 添加第一个元素
				var first_item = value_part.substr(1).strip_edges()
				if not first_item.is_empty():
					array_data.append(parse_simple_value(first_item))

				# 继续读取后续的数组项
				line_num += 1
				while line_num < lines.size():
					var next_line = lines[line_num].strip_edges()
					if next_line.is_empty() or next_line.begins_with("#"):
						line_num += 1
						continue

					# 计算下一行的缩进
					var next_indent = 0
					for char in next_line:
						if char == " ":
							next_indent += 1
						elif char == "\t":
							next_indent += 4
						else:
							break

					# 如果缩进回到当前级别或更少，停止读取数组
					if next_indent <= current_indent:
						line_num -= 1  # 回退一行
						break

					# 解析数组项
					if next_line.begins_with("-"):
						var item = next_line.substr(1).strip_edges()
						if not item.is_empty():
							array_data.append(parse_simple_value(item))
					else:
						break

					line_num += 1

				current_context[key] = array_data
			else:
				# 这是一个值
				var parsed_value = parse_simple_value(value_part)
				current_context[key] = parsed_value

		return LoadResult.new(true, result_data)

	static func parse_simple_value(value_str: String) -> Variant:
		# 处理带引号的字符串
		if value_str.begins_with("\"") and value_str.ends_with("\""):
			return value_str.substr(1, value_str.length() - 2)

		if value_str.begins_with("'") and value_str.ends_with("'"):
			return value_str.substr(1, value_str.length() - 2)

		# 处理布尔值
		var lower_value = value_str.to_lower()
		if lower_value == "true":
			return true
		if lower_value == "false":
			return false

		# 处理数字
		if value_str.is_valid_int():
			return value_str.to_int()

		if value_str.is_valid_float():
			return value_str.to_float()

		# 处理 null
		if lower_value in ["null", "~"]:
			return null

		# 默认返回字符串
		return value_str

	
	static func parse_multiline_string(lines: PackedStringArray, start_idx: int, base_indent: int) -> Dictionary:
		var content = ""
		var lines_read = 0

		for i in range(start_idx, lines.size()):
			var line = lines[i]

			# 如果遇到相同或更小缩进的非空行，停止解析
			if not line.strip_edges().is_empty():
				var line_indent = get_indentation_level(line)
				if line_indent <= base_indent:
					break

			content += line + "\n"
			lines_read += 1

		return {
			"content": content.strip_edges(),
			"lines_read": lines_read
		}

	static func parse_array(lines: PackedStringArray, start_idx: int, base_indent: int) -> Dictionary:
		var array = []
		var lines_read = 0

		for i in range(start_idx + 1, lines.size()):
			var line = lines[i]
			var stripped_line = line.strip_edges()

			# 如果遇到相同或更小缩进的非空行，停止解析
			if not stripped_line.is_empty() and not stripped_line.begins_with("-"):
				var line_indent = get_indentation_level(line)
				if line_indent <= base_indent:
					break

			# 解析数组项
			if stripped_line.begins_with("-"):
				var item_content = stripped_line.substr(1).strip_edges()

				if item_content.is_empty():
					# 这是一个复杂对象或嵌套数组
					# 获取下一行的缩进级别来确定类型
					if i + 1 < lines.size():
						var next_line = lines[i + 1]
						var next_indent = get_indentation_level(next_line)

						# 如果下一行缩进更深，这是一个嵌套对象
						if next_indent > get_indentation_level(line):
							var nested_result = parse_nested_structure(lines, i + 1, next_indent)
							array.append(nested_result.data)
							lines_read += nested_result.lines_read
							i += nested_result.lines_read
						else:
							# 空的数组项
							array.append({})
				else:
					# 解析数组项的值
					var value = parse_simple_value(item_content)
					array.append(value)

			lines_read += 1

		return {
			"array": array,
			"lines_read": lines_read
		}

	static func parse_nested_structure(lines: PackedStringArray, start_idx: int, base_indent: int) -> Dictionary:
		var data = {}
		var lines_read = 0

		for i in range(start_idx, lines.size()):
			var line = lines[i]
			var stripped_line = line.strip_edges()

			# 如果遇到相同或更小缩进的非空行，停止解析
			if not stripped_line.is_empty():
				var line_indent = get_indentation_level(line)
				if line_indent <= base_indent:
					break

			# 解析键值对
			var parts = stripped_line.split(":", false, 1)
			if parts.size() == 2:
				var key = parts[0].strip_edges()
				var value_str = parts[1].strip_edges()

				var value = parse_simple_value(value_str)
				if value is Dictionary and value.size() == 0:
					# 这可能是一个嵌套对象
					var nested_result = parse_nested_structure(lines, i + 1, get_indentation_level(line))
					data[key] = nested_result.data
					lines_read += nested_result.lines_read
					i += nested_result.lines_read
				else:
					data[key] = value

			lines_read += 1

		return {
			"data": data,
			"lines_read": lines_read
		}

	static func get_indentation_level(line: String) -> int:
		var indent = 0
		for char in line:
			if char == " ":
				indent += 1
			elif char == "\t":
				indent += 4  # 假设tab为4个空格
			else:
				break
		return indent

	static func parse_object_array_item(lines: PackedStringArray, start_idx: int, base_indent: int) -> Dictionary:
		# 解析对象数组项，如:
		# - track_id: "value"
		#   other_key: "value"
		var object_data = {}
		var i = start_idx + 1  # 从下一行开始解析

		while i < lines.size():
			var line = lines[i]
			var stripped = line.strip_edges()

			# 跳过空行和注释
			if stripped.is_empty() or stripped.begins_with("#"):
				i += 1
				continue

			# 计算缩进
			var indent = 0
			for char in line:
				if char == " ":
					indent += 1
				elif char == "\t":
					indent += 4
				else:
					break

			# 如果缩进回到基准级别或更少，对象结束
			if indent <= base_indent:
				break

			# 解析键值对
			if ":" in stripped:
				var parts = stripped.split(":", false, 1)
				if parts.size() == 2:
					var key = parts[0].strip_edges()
					var value_str = parts[1].strip_edges()
					object_data[key] = parse_simple_value(value_str)

			i += 1

		return {
			"object": object_data,
			"end_line": i - 1
		}

# 主配置加载方法
static func load_yaml_config(file_path: String) -> LoadResult:
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		return LoadResult.new(false, {}, ErrorType.FILE_NOT_FOUND, "配置文件不存在: " + file_path)

	# 读取文件内容
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return LoadResult.new(false, {}, ErrorType.FILE_NOT_FOUND, "无法打开配置文件: " + file_path)

	var yaml_content = file.get_as_text()
	file.close()

	# 解析YAML内容
	var parse_result = YAMLParser.parse(yaml_content)

	if not parse_result.success:
		return parse_result

	# 验证配置
	var validation_result = validate_config(parse_result.data)
	if not validation_result.success:
		return validation_result

	return parse_result

# 验证配置格式
static func validate_config(config: Dictionary) -> LoadResult:
	# 基础验证：确保配置不为空
	if config.is_empty():
		return LoadResult.new(false, {}, ErrorType.VALIDATION_ERROR, "配置文件为空")

	return LoadResult.new(true, config)

# 加载特定类型的配置
static func load_character_config(file_path: String) -> LoadResult:
	var result = load_yaml_config(file_path)
	if not result.success:
		return result

	# 验证角色配置格式
	var data = result.data
	if not data.has("characters"):
		return LoadResult.new(false, {}, ErrorType.VALIDATION_ERROR, "角色配置文件缺少 'characters' 节")

	return result

static func load_scene_config(file_path: String) -> LoadResult:
	var result = load_yaml_config(file_path)
	if not result.success:
		return result

	# 验证场景配置格式
	var data = result.data
	if not data.has("scenes"):
		return LoadResult.new(false, {}, ErrorType.VALIDATION_ERROR, "场景配置文件缺少 'scenes' 节")

	return result

static func load_ai_model_config(file_path: String) -> LoadResult:
	var result = load_yaml_config(file_path)
	if not result.success:
		return result

	# 验证AI模型配置格式
	var data = result.data
	if not data.has("ai_models"):
		return LoadResult.new(false, {}, ErrorType.VALIDATION_ERROR, "AI模型配置文件缺少 'ai_models' 节")

	return result

# 保存配置为YAML格式
static func save_yaml_config(data: Dictionary, file_path: String) -> bool:
	var yaml_content = dict_to_yaml(data, 0)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("无法创建配置文件: ", file_path)
		return false

	file.store_string(yaml_content)
	file.close()
	return true

# 将字典转换为YAML字符串
static func dict_to_yaml(data: Dictionary, indent_level: int) -> String:
	var yaml = ""
	var indent = "  ".repeat(indent_level)

	for key in data.keys():
		var value = data[key]

		if value is Dictionary:
			yaml += indent + str(key) + ":\n"
			yaml += dict_to_yaml(value, indent_level + 1)
		elif value is Array:
			yaml += indent + str(key) + ":\n"
			yaml += array_to_yaml(value, indent_level + 1)
		elif value is String and value.contains("\n"):
			# 多行字符串
			yaml += indent + str(key) + " |\n"
			for line in (value as String).split("\n"):
				yaml += "  " + indent + line + "\n"
		else:
			yaml += indent + str(key) + ": " + value_to_yaml(value) + "\n"

	return yaml

static func array_to_yaml(array: Array, indent_level: int) -> String:
	var yaml = ""
	var indent = "  ".repeat(indent_level)

	for item in array:
		if item is Dictionary:
			yaml += indent + "-\n"
			yaml += dict_to_yaml(item, indent_level + 1)
		elif item is Array:
			yaml += indent + "-\n"
			yaml += array_to_yaml(item, indent_level + 1)
		else:
			yaml += indent + "- " + value_to_yaml(item) + "\n"

	return yaml


static func value_to_yaml(value: Variant) -> String:
	if value is String:
		# 如果包含特殊字符，添加引号
		var str_val = value as String
		if str_val.contains(":") or str_val.contains("#") or str_val.contains("-"):
			return "\"" + str_val + "\""
		return str_val
	else:
		return str(value)
