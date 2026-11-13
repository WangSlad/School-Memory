# 运行时架构

`scenes/main.tscn` 是游戏根场景，持有一个玩家、HUD 和世界容器；`world/campus.tscn` 是校园世界，拥有校园专属的天空、灯光、音乐与场景物件。`scenes/templates/student_character.tscn` 包含角色、脚步及摄像机；摄像机控制脚本提供 FREE / FIXED 模式和 `apply_preset` 接口，可在此基础上扩展区域策略；默认仍为自由视角。现有资源和组件保留在原位置，以免破坏引用。

`GameTime` 是 Autoload，提供 `current_hour`、`time_running`、`day_duration_seconds`、`set_time(hour)` 和 `time_changed` 信号。校园昼夜表现与路灯消费这个时间，不负责推进时钟。

未来世界使用 Node3D 作为根节点。通过游戏根节点的 `change_world(packed_scene, spawn_name)` 切换；目标场景可包含同名 Marker3D 作为入口。未指定入口时，已访问场景恢复上次离开的位置；首次访问必须有名为 `DefaultSpawn` 的 Marker3D；指定入口不存在或缺少默认入口时切换失败，当前世界和玩家保持不变。玩家和 HUD 不随世界销毁，时间继续运行。当前接口不负责异步加载、转场或持久化。小地图由根节点注入玩家及摄像机目标；室内世界可按需要扩展 HUD 策略或隐藏它。

未来交互与 NPC 应使用各自场景和组件，日程读取 GameTime；跨场景状态及存档可在需求明确后单独建立，不放入校园场景或提前创建空管理器。

教学楼世界为 `res://world/teaching_building1.tscn`，通过 `change_world(load("res://world/teaching_building1.tscn"))` 进入；返回校园时传入 `res://world/campus.tscn`。两个世界共用 GameTime、玩家和 HUD，小地图随玩家移动；各自的昼夜环境在加载时读取同一时钟。当前没有内置世界切换交互。
