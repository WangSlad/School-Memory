# 五层教学楼独立测试

在 Godot 中打开 `res://scenes/teaching_building/teaching_building_test.tscn`，按 F6。WASD 移动，Shift 加速。测试角色从一层楼梯入口出生；各层 `FloorInterfaces/Floor_XX/Spawn` 在运行时创建，可作为其他层的出生点。

建筑可复用场景为 `teaching_building.tscn`。每层的 `Classroom_XX` 含 `room_id`、空的 `scene_transition_target` 和前后门 Marker3D；`CameraRegionAnchor` 和楼层 `occlusion_interface` 是未来系统的占位接口，当前没有遮挡切换逻辑。门保持关闭，不含教室内部。

无界面验证（在项目根目录，使用本机 Godot 4 可执行文件）：

```
godot --headless --path . --script res://scenes/teaching_building/verify_movement.gd
godot --headless --path . --script res://scenes/teaching_building/verify_collisions.gd
```

生成脚本使用上一阶段的 `teaching_floor.blend`，输出独立五层源文件与 GLB。改动尺寸时，需同时调整 Godot 场景脚本中楼梯碰撞及接口坐标；仅修改 Blender 参数不会自动同步它们。

测试场景使用春日暖色天空、投影太阳和一盏无阴影方向反弹光。测试角色与正式教学楼 world 共用 `indoor_camera.gd`：鼠标旋转自由，不改写水平或俯仰角，只限制实际相机高度，并检测实墙、楼板。相机可越过走廊栏杆；栏杆保留人物碰撞，但不挤压相机。走廊与楼梯间采用连续区域权重平滑缩距，楼梯目标跟随距离为 1.8 米；墙角预检测和恢复滞后避免交界处突然收放。教学楼不使用遮挡透明；回到校园恢复室外相机姿态、缩放及视野。灯光设置位于本测试场景。

正式游戏的室内小地图使用 `indoor_minimap.gd` 与独立渲染世界，共享原始网格但使用楼层剖切材质，显示当前楼层的走廊、房间边界、楼梯及楼层编号。上层楼板、屋顶和下层不会进入地图；切换楼层时带平台高度滞后，返回校园恢复室外地图。

正式教学楼 world 为 `world/teaching_building1.tscn`、`world/teaching_building2.tscn` 和 `world/teaching_building3.tscn`，依次对应校园中从前到后的 `ChunhuiBuilding3`、`ChunhuiBuilding4`、`ChunhuiBuilding5`。三者使用相同建筑、光照、人物比例和移速、室内相机与楼层小地图配置；各自出口返回对应楼前，场景路径不同，因此各楼的位置记录互相独立。入口和往返配置验证：`godot --headless --path . --script tools/verify_teaching_worlds.gd`。

`ceiling_lights.gd` 为三栋教学楼共用的五层建筑生成吸顶灯，覆盖走廊、房间和两处楼梯间，楼梯灯贴合上方平台或屋顶。灯色与校园路灯一致（`Color(1.0, 0.68, 0.36)`），同样由 `GameTime.time_changed` 控制黄昏渐亮、黎明渐灭；灯罩自发光与向下的局部投光同步，开启阴影防止穿墙照亮，并按距离淡出以控制渲染开销。灯具不新增碰撞。

三栋室内 `TeachingExit` 启用 `show_exit_marker`，复用入口的光圈和悬浮效果，改用 `assets/ui/teaching_exit.svg` 中的出门人形与箭头图案。出口中心为 `(118.4, 0.5, 1.4)`，半径为 0.75 米，图标与室外保持相同大小和高度。进入光圈后按 E 返回对应校园楼前。

校园三处教学楼入口启用 `interaction_area.gd` 的 `show_book_marker`，使用 `book_interaction_marker.gd` 显示悬浮书本圆牌与识别半径对应的地面环，人物进入范围时高亮，继续使用原有 E 键交互。识别中心从门前台阶向建筑外侧偏移 0.8 米，半径为 0.75 米，光圈自动贴地；书本圆牌显示尺寸为初版的一半，局部高度为 0.65 米（相对识别区中心）。图标源文件为 `assets/ui/teaching_book.svg`。验证命令：`godot --headless --path . --script tools/verify_teaching_lights.gd`；图形模式增加 `-- --capture` 可在 `docs/teaching_world_review/` 生成入口、昼夜走廊及夜间楼梯截图。

相机和楼层地图验证：`godot --headless --path . --script tools/verify_teaching_camera.gd`；增加 `-- --capture` 并使用图形模式可生成一、三、五层的实际游戏画面与小地图。

原五层建筑已默认接入“春日和风 · 轻复古校园”材质。`teaching_building.gd` 的 `spring_materials_enabled` 控制材质覆盖，`facade_relief_enabled` 控制新增的实体墙裙、压顶、门窗背衬与窗台凸台。局部收口嵌入原墙面，不改变原模型、走廊跨度和碰撞。贴图生成、外部归档、实际截图与验证结果见 [材质交付说明](../../docs/teaching_spring_materials.md)。


当前层高 4.32 米；走廊 4.8 米、教室柱间距 10.4 米、单跑楼梯宽 2.1 米；立面门窗随开间按水平方向等比例调整。


左侧新增楼梯间位于阳台与办公室之间。两处楼梯使用实心侧墙及中央折返扶手；左侧楼梯自动通行检查为 `godot --headless --path . --script res://scenes/teaching_building/verify_left_stair.gd`。


2026-11-13 门窗细化与显示修复：`joinery_detail_enabled` 默认开启，提供木制嵌板、合页、拉手、窗扇、密封条和锁扣。教室窗使用独立雾蓝反射材质；栏杆玻璃由 `glazing_panels.gd` 分为独立面板排序，原合并渲染隐藏但原碰撞保留。详细验证可运行 `res://tools/verify_teaching_joinery.gd`。

最右侧bay13已默认改为每层男左女右两个独立卫生间，包含内部隔墙、洁具及门上图文标识。restrooms_enabled可控制本次房间改造；详见 [卫生间改造说明](../../docs/teaching_restrooms.md)。
