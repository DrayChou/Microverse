extends RefCounted
class_name SimpleYAMLParser

# 简化的 YAML 解析器，专注于处理我们的配置文件格式
# 支持基本的键值对和嵌套结构

class ParseResult:
	var success: bool = false
	var data: Dictionary = {}
	var error_message: String = ""

	func _init(p_success: bool = false, p_data: Dictionary = {}, p_error_message: String = ""):
		success = p_success
		data = p_data
		error_message = p_error_message

static func parse(yaml_content: String) -> ParseResult:
	if yaml_content.is_empty():
		return ParseResult.new(false, {}, "YAML内容为空")

	var result_data = {}
	var lines = yaml_content.split("\n")
	var context_stack = [result_data]  # 用于跟踪嵌套上下文
	var indent_stack = [-1]  # 用于跟踪缩进级别

	for line_num in range(lines.size()):
		var original_line = lines[line_num]
		var line = original_line.strip_edges(true, false)  # 只去掉右边空白，保留左边缩进

		# 跳过空行和注释
		if line.strip_edges().is_empty() or line.strip_edges().begins_with("#"):
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
		print("第", line_num + 1, "行: 缩进=", current_indent, " 内容='", content, "'")

		# 处理键值对
		var colon_index = content.find(":")
		if colon_index == -1:
			return ParseResult.new(false, {}, "第%d行：缺少冒号 - %s" % [line_num + 1, content])

		var key = content.substr(0, colon_index).strip_edges()
		var value_part = content.substr(colon_index + 1).strip_edges()

		# 确定当前上下文（根据缩进）
		while indent_stack.size() > 1 and indent_stack[-1] >= current_indent:
			context_stack.pop_back()
			indent_stack.pop_back()

		var current_context = context_stack[-1]

		if value_part.is_empty():
			# 这是一个嵌套对象
			var new_object = {}
			current_context[key] = new_object
			context_stack.append(new_object)
			indent_stack.append(current_indent)
			print("  创建嵌套对象: ", key)
		else:
			# 这是一个值
			var parsed_value = parse_simple_value(value_part)
			current_context[key] = parsed_value
			print("  设置值: ", key, " = ", parsed_value)

	print("解析完成，结果: ", result_data)
	return ParseResult.new(true, result_data)

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