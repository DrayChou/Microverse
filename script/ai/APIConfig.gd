# APIConfig.gd - API配置管理器 v2.0
# 统一管理所有API相关的配置信息，从YAML配置文件加载，避免硬编码

class_name APIConfig

# API类型枚举
enum APIType {
	OLLAMA,
	LMSTUDIO,
	OPENAI,
	DEEPSEEK,
	DOUBAO,
	GEMINI,
	CLAUDE,
	SILICONFLOW,
	KIMI,
	OPENAI_COMPATIBLE
}

# API配置数据结构
class APIProvider:
	var name: String
	var display_name: String
	var base_url: String
	var endpoints: Dictionary
	var models: Array[String]
	var requires_api_key: bool
	var headers_template: Dictionary
	var request_format: String
	var response_parser: String
	var timeout: float
	var max_retries: int
	var pricing: Dictionary

	func _init(n: String, dn: String, url: String, ep: Dictionary, m: Array[String], req_key: bool, headers: Dictionary, req_fmt: String, resp_parser: String, to: float = 30.0, retries: int = 3, price: Dictionary = {}):
		name = n
		display_name = dn
		base_url = url
		endpoints = ep
		models = m
		requires_api_key = req_key
		headers_template = headers
		request_format = req_fmt
		response_parser = resp_parser
		timeout = to
		max_retries = retries
		pricing = price

# 从YAML配置加载的提供商数据
static var _providers: Dictionary = {}
static var _model_display_names: Dictionary = {}
static var _initialized: bool = false
static var _content_manager: ContentManager

# 初始化 - 从配置文件加载
static func _initialize():
	if _initialized:
		return

	print("[APIConfig] 正在从配置文件初始化API配置（优先JSON，回退YAML）...")

	# 获取ContentManager实例
	_content_manager = ContentManager.get_instance()
	if _content_manager == null:
		print("[APIConfig错误] ContentManager未初始化，使用默认配置")
		_load_fallback_config()
		_initialized = true
		return

	# 加载AI模型配置
	var ai_config = _content_manager.get_all_ai_providers()
	if ai_config.is_empty():
		print("[APIConfig错误] 无法加载AI配置，使用默认配置")
		_load_fallback_config()
		_initialized = true
		return

	# 解析提供商配置
	_parse_providers_from_config(ai_config)

	# 解析模型显示名称
	_parse_model_display_names(ai_config)

	_initialized = true
	print("[APIConfig] 配置初始化完成，加载了 ", _providers.size(), " 个API提供商")

# 解析提供商配置
static func _parse_providers_from_config(ai_config: Dictionary):
	# 直接使用传入的providers配置
	var providers_config = ai_config

	for provider_name in providers_config.keys():
		var provider_data = providers_config[provider_name]

		# 构建端点映射
		var endpoints = {}
		if provider_data.has("endpoints"):
			for endpoint_name in provider_data.endpoints:
				endpoints[endpoint_name] = provider_data.endpoints[endpoint_name]

		# 获取模型列表
		var models: Array[String] = []
		if provider_data.has("models"):
			for model_data in provider_data.models:
				models.append(model_data.get("id", ""))

		# 获取请求头模板
		var headers_template = {}
		if provider_data.has("authentication"):
			var auth = provider_data.authentication
			if auth.has("type") and auth.type == "api_key":
				var key_header = auth.get("key_header", "Authorization")
				var key_prefix = auth.get("key_prefix", "Bearer")
				headers_template[key_header] = key_prefix + " {api_key}"

		# 添加通用请求头
		if provider_data.has("headers"):
			for header_name in provider_data.headers:
				headers_template[header_name] = provider_data.headers[header_name]

		# 获取定价信息
		var pricing = {}
		if provider_data.has("pricing"):
			pricing = provider_data.pricing

		# 创建APIProvider实例
		var provider = APIProvider.new(
			provider_name,
			provider_data.get("display_name", provider_name),
			provider_data.get("base_url", ""),
			endpoints,
			models,
			provider_data.get("requires_api_key", true),
			headers_template,
			provider_data.get("request_format", "openai"),
			provider_data.get("response_parser", "openai"),
			provider_data.get("timeout", 30.0),
			provider_data.get("max_retries", 3),
			pricing
		)

		_providers[provider_name] = provider

# 解析模型显示名称
static func _parse_model_display_names(ai_config: Dictionary):
	_model_display_names.clear()

	# 直接使用传入的providers配置
	var providers_config = ai_config
	for provider_name in providers_config.keys():
		var provider_data = providers_config[provider_name]
		if provider_data.has("models"):
			for model_data in provider_data.models:
				var model_id = model_data.get("id", "")
				var display_name = model_data.get("display_name", model_id)
				if not model_id.is_empty():
					_model_display_names[model_id] = display_name

# 备用配置（当YAML配置加载失败时使用）
static func _load_fallback_config():
	print("[APIConfig] 加载备用配置...")

	# 基本的LMStudio配置作为备用
	_providers["LMStudio"] = APIProvider.new(
		"LMStudio",
		"LMStudio (本地)",
		"http://localhost:11435",
		{"chat": "/v1/chat/completions"},
		["qwen/qwen3-vl-4b"],
		false,
		{"Content-Type": "application/json"},
		"openai",
		"openai"
	)

# 获取所有API提供商名称
static func get_api_types() -> Array[String]:
	_initialize()
	var result: Array[String] = []
	for key in _providers.keys():
		result.append(key)
	return result

# 获取API提供商配置
static func get_provider(api_type: String) -> APIProvider:
	_initialize()
	if _providers.has(api_type):
		return _providers[api_type]

	# 如果找不到指定提供商，返回第一个可用的
	if not _providers.is_empty():
		var first_key = _providers.keys()[0]
		print("[APIConfig警告] 未找到提供商 '", api_type, "'，使用备用 '", first_key, "'")
		return _providers[first_key]

	# 最后的备用选择
	return _providers.get("LMStudio", null)

# 获取指定API的模型列表
static func get_models_for_api(api_type: String) -> Array[String]:
	_initialize()
	var provider = get_provider(api_type)
	if provider:
		return provider.models
	return []

# 检查API是否需要密钥
static func requires_api_key(api_type: String) -> bool:
	_initialize()
	var provider = get_provider(api_type)
	if provider:
		return provider.requires_api_key
	return true

# 构建请求数据
static func build_request_data(api_type: String, model: String, prompt: String, messages: Array = []) -> Dictionary:
	_initialize()
	var provider = get_provider(api_type)

	if not provider:
		print("[APIConfig错误] 无法找到API提供商: ", api_type)
		return {}

	match provider.request_format:
		"ollama":
			return {
				"model": model,
				"prompt": prompt,
				"stream": false
			}
		"openai":
			# 如果提供了messages数组就使用，否则构建单条消息
			var message_array = messages
			if message_array.is_empty():
				message_array = [{"role": "user", "content": prompt}]

			return {
				"model": model,
				"messages": message_array
			}
		"gemini":
			return {
				"contents": [{
					"parts": [{"text": prompt}]
				}]
			}
		"claude":
			return {
				"model": model,
				"max_tokens": 1024,
				"messages": [{"role": "user", "content": prompt}]
			}
		_:
			print("[APIConfig错误] 未知的请求格式: ", provider.request_format)
			return {}

# 构建请求头
static func build_headers(api_type: String, api_key: String = "") -> Array[String]:
	_initialize()
	var provider = get_provider(api_type)

	if not provider:
		return []

	var headers: Array[String] = []

	for key in provider.headers_template:
		var value = provider.headers_template[key]
		if not api_key.is_empty() and value.find("{api_key}") != -1:
			value = value.replace("{api_key}", api_key)
		headers.append(key + ": " + value)

	return headers

# 获取请求URL
static func get_url(api_type: String, endpoint_type: String = "chat", model: String = "") -> String:
	_initialize()
	var provider = get_provider(api_type)

	if not provider:
		print("[APIConfig错误] 无法找到API提供商: ", api_type)
		return ""

	var url = provider.base_url

	# 添加端点路径
	if provider.endpoints.has(endpoint_type):
		url += provider.endpoints[endpoint_type]

	# 替换模型占位符
	if url.find("{model}") != -1:
		url = url.replace("{model}", model)

	return url

# 解析API响应
static func parse_response(api_type: String, response: Dictionary, character_name: String = "") -> String:
	_initialize()
	var provider = get_provider(api_type)

	if not provider:
		print("[APIConfig错误] 无法找到API提供商: ", api_type)
		return ""

	match provider.response_parser:
		"ollama":
			if not response.has("response"):
				print("[APIConfig] ", character_name, " 的Ollama API响应格式错误：缺少response字段")
				return ""
			return response.response

		"openai":
			if not response.has("choices") or response.choices.size() == 0:
				print("[APIConfig] ", character_name, " 的OpenAI格式API响应错误：缺少choices字段或为空")
				return ""
			if not response.choices[0].has("message") or not response.choices[0].message.has("content"):
				print("[APIConfig] ", character_name, " 的OpenAI格式API响应错误：缺少message或content字段")
				return ""
			return response.choices[0].message.content

		"gemini":
			if not response.has("candidates") or response.candidates.size() == 0:
				print("[APIConfig] ", character_name, " 的Gemini API响应格式错误：缺少candidates字段或为空")
				return ""
			if not response.candidates[0].has("content") or not response.candidates[0].content.has("parts") or response.candidates[0].content.parts.size() == 0:
				print("[APIConfig] ", character_name, " 的Gemini API响应格式错误：缺少content或parts字段")
				return ""
			return response.candidates[0].content.parts[0].text

		"claude":
			if not response.has("content") or response.content.size() == 0:
				print("[APIConfig] ", character_name, " 的Claude API响应格式错误：缺少content字段或为空")
				return ""
			if not response.content[0].has("text"):
				print("[APIConfig] ", character_name, " 的Claude API响应格式错误：缺少text字段")
				return ""
			return response.content[0].text

		_:
			print("[APIConfig] ", character_name, " 未知的响应解析器: ", provider.response_parser)
			return ""

# 获取模型的显示名称
static func get_model_display_name(model_id: String) -> String:
	_initialize()
	if _model_display_names.has(model_id):
		return _model_display_names[model_id]
	else:
		# 如果没有映射，返回原ID（但做一些格式化）
		var display_name = model_id
		# 移除常见的命名空间前缀
		if display_name.find("/") != -1:
			var parts = display_name.split("/")
			if parts.size() > 1:
				display_name = parts[1]
		return display_name

# 获取提供商定价信息
static func get_provider_pricing(provider_name: String) -> Dictionary:
	_initialize()
	var provider = get_provider(provider_name)
	if provider:
		return provider.pricing
	return {}

# 重新加载配置（用于热重载）
static func reload_configs():
	_initialized = false
	_providers.clear()
	_model_display_names.clear()
	_initialize()

# 检查配置是否有效
static func validate_config() -> bool:
	_initialize()
	if _providers.is_empty():
		print("[APIConfig错误] 没有加载任何API提供商配置")
		return false

	# 检查默认提供商是否存在
	if not _providers.has("LMStudio"):
		print("[APIConfig警告] 未找到默认LMStudio提供商")

	return true
