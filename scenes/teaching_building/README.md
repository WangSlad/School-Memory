# 五层教学楼独立测试

在 Godot 中打开 `res://scenes/teaching_building/teaching_building_test.tscn`，按 F6。WASD 移动，Shift 加速。测试角色从一层楼梯入口出生；各层 `FloorInterfaces/Floor_XX/Spawn` 在运行时创建，可作为其他层的出生点。

建筑可复用场景为 `teaching_building.tscn`。每层的 `Classroom_XX` 含 `room_id`、空的 `scene_transition_target` 和前后门 Marker3D；`CameraRegionAnchor` 和楼层 `occlusion_interface` 是未来系统的占位接口，当前没有遮挡切换逻辑。门保持关闭，不含教室内部。

无界面验证（在项目根目录，使用本机 Godot 4 可执行文件）：

```
godot --headless --path . --script res://scenes/teaching_building/verify_movement.gd
godot --headless --path . --script res://scenes/teaching_building/verify_collisions.gd
```

生成脚本使用上一阶段的 `teaching_floor.blend`，输出独立五层源文件与 GLB。改动尺寸时，需同时调整 Godot 场景脚本中楼梯碰撞及接口坐标；仅修改 Blender 参数不会自动同步它们。

测试场景使用春日暖色天空、投影太阳和一盏无阴影方向反弹光；测试角色使用可自动避障缩距的摄像机。灯光设置位于本测试场景。

原五层建筑已默认接入“春日和风 · 轻复古校园”材质。`teaching_building.gd` 的 `spring_materials_enabled` 控制材质覆盖，`facade_relief_enabled` 控制新增的实体墙裙、压顶、门窗背衬与窗台凸台。局部收口嵌入原墙面，不改变原模型、走廊跨度和碰撞。贴图生成、外部归档、实际截图与验证结果见 [材质交付说明](../../docs/teaching_spring_materials.md)。


当前层高 4.32 米；走廊 4.8 米、教室柱间距 10.4 米、单跑楼梯宽 2.1 米；立面门窗随开间按水平方向等比例调整。


左侧新增楼梯间位于阳台与办公室之间。两处楼梯使用实心侧墙及中央折返扶手；左侧楼梯自动通行检查为 `godot --headless --path . --script res://scenes/teaching_building/verify_left_stair.gd`。


2026-11-13 门窗细化与显示修复：`joinery_detail_enabled` 默认开启，提供木制嵌板、合页、拉手、窗扇、密封条和锁扣。教室窗使用独立雾蓝反射材质；栏杆玻璃由 `glazing_panels.gd` 分为独立面板排序，原合并渲染隐藏但原碰撞保留。详细验证可运行 `res://tools/verify_teaching_joinery.gd`。

最右侧bay13已默认改为每层男左女右两个独立卫生间，包含内部隔墙、洁具及门上图文标识。restrooms_enabled可控制本次房间改造；详见 [卫生间改造说明](../../docs/teaching_restrooms.md)。
