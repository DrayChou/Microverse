# 任务管理系统架构文档

## 📋 概述

Microverse项目实现了一套完整的AI驱动任务管理系统，通过动态任务生成、智能优先级排序、AI自主执行决策和多角色协作机制，为虚拟角色提供了真实的工作任务体验。任务系统与记忆系统、对话系统和AI决策系统深度集成，形成了完整的角色行为生态。

## 🏗️ 任务系统架构

### 1. 核心组件

```
任务管理系统
├── 任务生成器 (AIAgent._generate_random_task)
├── 任务执行器 (AIAgent._execute_current_task)
├── 任务完成检测 (AIAgent._complete_task)
├── 任务持久化 (GameSaveManager)
└── 任务UI管理 (GodUI)
```

### 2. 数据流程

```
任务生成 → 优先级排序 → AI决策执行 → 完成检测 → 记忆更新 → 持久化保存
    ↓         ↓           ↓          ↓         ↓         ↓
角色人设   渴望程度   四步执行策略  自主判断   生成记忆   存档恢复
```

## 📝 任务数据结构

### 1. 任务对象定义

```json
{
  "description": "任务描述文本",
  "priority": 7,                    // 渴望程度 (1-10)
  "created_at": 1704110400.0,       // 创建时间戳
  "completed": false,               // 完成状态
  "completed_at": 0.0               // 完成时间戳
}
```

### 2. 任务存储位置

**运行时存储** ([`AIAgent.gd:413`](script/ai/AIAgent.gd#L413)):
```gdscript
# 任务存储在角色元数据中
character_node.set_meta("tasks", incomplete_tasks)
```

**持久化存储** ([`GameSaveManager.gd:160-164`](script/GameSaveManager.gd#L160-L164)):
```gdscript
# 存档时收集任务数据
if ai_agent.has_property("current_tasks"):
    character_data["tasks"] = ai_agent.current_tasks.duplicate()
```

## 🎲 任务生成机制

### 1. 动态任务生成

**任务生成器** ([`AIAgent.gd:425-490`](script/ai/AIAgent.gd#L425-L490)):

```gdscript
func _generate_random_task(character_node):
    # 1. 获取角色人设
    var personality = CharacterPersonality.get_personality(character_node.name)

    # 2. 构建任务池
    var tasks_pool = []

    # 3. 添加通用任务
    tasks_pool.append("检查邮件")
    tasks_pool.append("整理工作区")
    # ... 更多通用任务

    # 4. 根据职位添加特定任务
    if personality["position"].to_lower().contains("经理"):
        tasks_pool.append("审核团队报告")
        tasks_pool.append("分配工作任务")
    elif personality["position"].to_lower().contains("技术"):
        tasks_pool.append("修复技术问题")
        tasks_pool.append("开发新功能")

    # 5. 随机选择任务和优先级
    var random_task = tasks_pool[randi() % tasks_pool.size()]
    var random_priority = randi() % 10 + 1

    return {
        "description": random_task,
        "priority": random_priority,
        "created_at": Time.get_unix_time_from_system(),
        "completed": false
    }
```

### 2. 职位特定任务

**管理层任务**:
- 审核团队报告
- 分配工作任务
- 评估团队表现
- 制定部门策略
- 与其他部门协调

**技术岗位任务**:
- 修复技术问题
- 开发新功能
- 代码审查
- 技术文档编写
- 系统测试

**销售岗位任务**:
- 联系潜在客户
- 准备销售演示
- 跟进销售线索
- 更新客户资料
- 制定销售策略

**人力资源任务**:
- 审核简历
- 安排面试
- 处理员工问题
- 组织团队活动
- 更新员工档案

### 3. 初始任务生成

**自动初始化** ([`AIAgent.gd:903-910`](script/ai/AIAgent.gd#L903-L910)):
```gdscript
func _check_and_initialize_tasks():
    var metadata = character.get_meta("character_data", {})
    if not metadata.has("tasks") or metadata["tasks"].size() == 0:
        print("[AIAgent] %s 没有任务数据，开始生成初始任务" % character.name)
        await _generate_initial_tasks()
```

## 🔄 任务执行流程

### 1. 四步执行策略

**AI决策模型** ([`AIAgent.gd:1220-1234`](script/ai/AIAgent.gd#L1220-L1234)):

```gdscript
match decision:
    "1":  # 移动 - 到达任务相关地点
        await _execute_task_movement(target_character, current_task)
    "2":  # 对话 - 与相关人员交流
        await _execute_task_conversation(target_character, current_task)
    "3":  # 思考 - 规划任务执行方案
        await _execute_task_thinking(target_character, current_task)
    "4":  # 完成 - 标记任务完成
        _complete_task(target_character, current_task)
```

### 2. 任务执行决策

**Prompt构建** ([`AIAgent.gd:1177-1179`](script/ai/AIAgent.gd#L1177-L1179)):
```gdscript
prompt += "\n\n你当前最重要的任务是：%s（渴望程度：%d）" % [current_task.description, current_task.priority]
prompt += "\n\n为了完成这个任务，你需要采取什么具体行动？请从以下选项中选择："
prompt += "\n1. 移动到某个位置（去找相关的人或物品）"
prompt += "\n2. 与某个角色交谈（讨论任务相关内容）"
prompt += "\n3. 思考规划（在当前位置思考如何完成任务）"
prompt += "\n4. 完成任务（任务已经可以标记为完成）"
```

### 3. 具体执行动作

**移动执行** ([`AIAgent.gd:1242-1295`](script/ai/AIAgent.gd#L1242-L1295)):
- 分析任务目标，确定需要到达的地点
- 使用AI选择目标位置（角色、物品、房间）
- 执行移动到目标位置
- 更新角色状态和记忆

**对话执行** ([`AIAgent.gd:1355-1395`](script/ai/AIAgent.gd#L1355-L1395)):
- 识别可对话的角色
- 选择对话对象
- 生成任务相关对话内容
- 执行对话并更新记忆

**思考执行** ([`AIAgent.gd:1500-1575`](script/ai/AIAgent.gd#L1500-L1575)):
- 分析当前任务状态
- 生成思考内容
- 规划下一步行动
- 添加思考记忆

## ✅ 任务完成机制

### 1. AI自主完成判断

**自我评估完成** ([`AIAgent.gd:1578-1598`](script/ai/AIAgent.gd#L1578-L1598)):
```gdscript
func _complete_task(target_character, current_task):
    # 1. 获取角色元数据
    var metadata = target_character.get_meta("character_data", {})
    var tasks = metadata.get("tasks", [])

    # 2. 找到并标记任务为完成
    for i in range(tasks.size()):
        var task = tasks[i]
        if task.description == current_task.description and task.created_at == current_task.created_at:
            task["completed"] = true
            task["completed_at"] = Time.get_unix_time_from_system()
            break

    # 3. 保存更新的任务列表
    metadata["tasks"] = tasks
    target_character.set_meta("character_data", metadata)

    # 4. 添加完成任务的记忆
    _add_memory(target_character, "你成功完成了任务：%s。感觉很有成就感！" % current_task.description)
```

### 2. 玩家手动完成

**UI操作完成** ([`GodUI.gd:663-692`](script/ui/GodUI.gd#L663-L692)):
```gdscript
func _on_complete_task(task_index):
    # 1. 标记任务为已完成
    var task = tasks[task_index]
    task["completed"] = true
    task["completed_at"] = Time.get_unix_time_from_system()

    # 2. 添加完成任务的记忆
    var memory_text = "你完成了任务：%s" % task["description"]
    MemoryManager.add_memory(selected_character, memory_text, MemoryManager.MemoryType.TASK)

    # 3. 从列表中移除已完成的任务
    tasks.remove_at(task_index)
    character_data["tasks"] = tasks
    selected_character.set_meta("character_data", character_data)
```

## 📊 任务管理系统

### 1. 任务刷新机制

**24小时自动刷新** ([`AIAgent.gd:375-422`](script/ai/AIAgent.gd#L375-L422)):
```gdscript
func refresh_daily_tasks(character_node):
    # 1. 保留未完成任务
    var incomplete_tasks = []
    for task in tasks:
        if not task.get("completed", false):
            incomplete_tasks.append(task)

    # 2. 重新排序任务（根据优先级从高到低）
    incomplete_tasks.sort_custom(func(a, b): return a["priority"] > b["priority"])

    # 3. 如果任务数量少于3个，自动生成新任务
    while incomplete_tasks.size() < 3:
        var new_task = _generate_random_task(character_node)
        if new_task:
            incomplete_tasks.append(new_task)

    # 4. 更新任务列表和刷新时间
    character_data["tasks"] = incomplete_tasks
    character_data["last_task_refresh"] = Time.get_unix_time_from_system()
```

### 2. 优先级管理

**优先级规则**:
- **渴望程度**: 1-10的随机值
- **排序机制**: 按优先级从高到低排序
- **执行顺序**: AI优先执行高优先级任务
- **动态调整**: 支持运行时优先级重新排序

### 3. 任务数量控制

**容量管理**:
- **最小任务数**: 3个任务
- **自动补充**: 不足3个时自动生成新任务
- **未完成保留**: 跨天保留未完成任务
- **完成清理**: 已完成任务自动移除

## 👥 多角色协作机制

### 1. 任务驱动对话

**对话与任务集成** ([`ConversationManager.gd:173-179`](script/ai/ConversationManager.gd#L173-L179)):
```gdscript
prompt += "\n\n请根据你的性格、当前状态、心情、任务和与对方的关系，生成一段自然的对话。"
prompt += "\n- 可以结合你的当前任务来聊天,当前突发的记忆优先级大于任务。"
```

### 2. 协作场景示例

**信息传递协作**:
- Alice需要UI设计反馈 → 与Joe对话 → 获取反馈 → 完成任务
- Stephen需要项目报告 → 与团队成员对话 → 收集信息 → 完成任务

**角色状态影响**:
- 任务完成生成记忆 → 影响情感关系 → 影响后续对话 → 影响新任务生成

### 3. 隐式依赖处理

虽然没有显式的任务依赖系统，但通过以下方式实现协作:

1. **时序依赖**: 任务按优先级排序执行
2. **空间依赖**: 通过移动到达特定地点
3. **社交依赖**: 通过对话获取信息或帮助
4. **状态依赖**: 基于当前环境状态判断执行条件

## 💾 任务持久化

### 1. 存档保存

**数据收集** ([`GameSaveManager.gd:160-164`](script/GameSaveManager.gd#L160-L164)):
```gdscript
# 任务数据
if ai_agent.has_property("current_tasks"):
    character_data["tasks"] = ai_agent.current_tasks.duplicate()
elif ai_agent.has_property("tasks"):
    character_data["tasks"] = ai_agent.tasks.duplicate()
```

### 2. 读档恢复

**数据恢复** ([`GameSaveManager.gd:248-253`](script/GameSaveManager.gd#L248-L253)):
```gdscript
# 恢复任务
if data.has("tasks"):
    if ai_agent.has_property("current_tasks"):
        ai_agent.current_tasks = data["tasks"].duplicate()
    elif ai_agent.has_property("tasks"):
        ai_agent.tasks = data["tasks"].duplicate()
```

### 3. 数据完整性

**保存内容**:
- 任务描述和优先级
- 创建和完成时间戳
- 完成状态标识
- 任务执行历史（通过记忆系统）

## 🎮 任务与AI决策集成

### 1. 决策输入

**任务状态作为决策依据** ([`AIAgent.gd:535-537`](script/ai/AIAgent.gd#L535-L537)):
```gdscript
# 获取任务信息
var task_info = get_character_task_info(character)

# 添加到决策prompt
prompt += task_info
```

### 2. 状态感知

**任务上下文格式化**:
```gdscript
# 当前任务列表：
# 1. 修复技术问题（渴望程度：8）
# 2. 代码审查（渴望程度：6）
# 3. 整理工作区（渴望程度：4）
```

### 3. 行为驱动

任务直接影响角色的行为选择:
- **高优先级任务** → 更积极的执行策略
- **对话类任务** → 寻找其他角色交流
- **移动类任务** → 到达特定地点
- **思考类任务** → 停留原地规划

## ⚠️ 系统局限性

### 1. 功能缺失

**当前未实现的功能**:
- ❌ 显式任务依赖关系定义
- ❌ 任务进度跟踪系统
- ❌ 任务失败判定机制
- ❌ 多人协作任务支持
- ❌ 任务模板和配置化管理
- ❌ 任务完成条件验证

### 2. 逻辑限制

**设计约束**:
- 任务完成完全依赖AI主观判断
- 缺少客观的完成条件验证
- 任务类型相对固定，扩展性有限
- 协作机制较为简单，依赖隐式交流

## 🚀 改进建议

### 1. 增强任务依赖系统

```json
{
  "id": "task_001",
  "description": "完成项目原型",
  "dependencies": ["task_002", "task_003"],
  "requirements": {
    "location": "开发部",
    "characters": ["Alice", "Bob"],
    "items": ["设计稿", "开发环境"],
    "conditions": ["设计已确认", "开发环境就绪"]
  },
  "progress": 0.0,
  "subtasks": [
    {
      "description": "UI设计完成",
      "completed": true,
      "assigned_to": "Alice"
    },
    {
      "description": "后端实现",
      "completed": false,
      "assigned_to": "Bob"
    }
  ]
}
```

### 2. 实现任务进度跟踪

```gdscript
class TaskProgress:
    var total_steps: int = 0
    var completed_steps: int = 0
    var current_step: int = 0

    func get_progress() -> float:
        if total_steps == 0:
            return 0.0
        return float(completed_steps) / float(total_steps)

    func update_progress(step_completed: bool):
        if step_completed:
            completed_steps += 1
        current_step += 1
```

### 3. 添加协作任务支持

```gdscript
class CollaborativeTask:
    var participants: Array[String] = []
    var shared_goal: String = ""
    var individual_roles: Dictionary = {}
    var completion_criteria: Dictionary = {}

    func check_completion_status() -> bool:
        # 检查所有参与者是否完成各自角色
        for participant in participants:
            if not is_participant_role_completed(participant):
                return false
        return true
```

### 4. 配置化任务模板

```yaml
# config/content/tasks/task_templates.yml
task_templates:
  office_work:
    manager:
      - description: "审核团队周报"
        priority_range: [7, 10]
        duration: "2-4 hours"
        required_skills: ["管理", "评估"]

    developer:
      - description: "修复Bug #{{bug_id}}"
        priority_range: [5, 9]
        duration: "1-3 hours"
        required_skills: ["编程", "调试"]

    designer:
      - description: "完成{{feature}}的UI设计"
        priority_range: [6, 8]
        duration: "3-6 hours"
        required_skills: ["设计", "创意"]
```

### 5. 任务失败机制

```gdscript
func check_task_failure(task: Dictionary, character: Node) -> bool:
    # 检查超时
    if Time.get_unix_time_from_system() - task.created_at > TASK_TIMEOUT:
        return true

    # 检查条件不满足
    if not validate_task_requirements(task, character):
        return true

    # 检查角色状态不适合
    if not is_character_suitable_for_task(character, task):
        return true

    return false
```

## 📈 最佳实践总结

### 1. 任务设计原则

- **角色适配**: 任务内容与角色职位和性格匹配
- **优先级合理**: 使用渴望程度体现任务重要性
- **数量适中**: 保持3-5个活跃任务，避免过载
- **类型多样**: 包含移动、对话、思考等多种执行方式

### 2. AI决策优化

- **上下文丰富**: 提供充分的任务状态信息
- **选择明确**: 提供清晰的执行选项
- **反馈及时**: 任务完成立即生成记忆
- **状态同步**: 任务状态与角色状态保持一致

### 3. 系统集成建议

- **记忆联动**: 任务完成生成重要记忆
- **对话驱动**: 通过对话解决任务需求
- **环境感知**: 任务执行考虑当前环境状态
- **角色互动**: 任务促进角色间有意义互动

### 4. 扩展方向

- **智能任务调度**: 基于角色状态和环境动态调整任务
- **复杂任务链**: 实现多步骤、多依赖的任务系统
- **协作优化**: 支持更复杂的多人协作任务
- **自适应难度**: 根据角色表现调整任务难度

---

*文档版本: v1.0*
*最后更新: 2024-11-10*
*维护者: AI开发团队*

这份任务管理系统文档全面分析了Microverse项目的任务管理机制，为新项目提供了完整的技术参考和改进建议。该系统展现了AI驱动任务管理的创新实现，特别是在任务生成、执行决策和多角色协作方面的独特设计。