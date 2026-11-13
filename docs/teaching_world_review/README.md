# 教学楼 world 比例与动态光照

教学楼 `world/teaching_building1.tscn` 的太阳正午高度为 60°，早晚分别从楼体两端照向走廊，柱子、扶手、窗框的投影随全局游戏时间移动。白天环境光 0.4、夜间 0.12，避免环境光过强掩盖投影；日光和月光均启用阴影，阴影距离为 80 米并混合级联。

教学楼根节点使用 `core/world_settings.gd`，人物尺寸 1.0、移速 4.0。相较校园尺寸 0.75、移速 2.0，人物大约放大 33%，移动速度提高至两倍。碰撞胶囊、脚底对齐、相机关注高度同步适配。游戏根节点在切换世界时应用配置，并在返回未指定配置的世界时恢复主场景的人物参数。

验证命令（在项目目录运行）：

```powershell
& 'D:\Research\GameDevelopment\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tools/verify_teaching_world.gd
& 'D:\Research\GameDevelopment\Godot_v4.7.2-stable_win64_console.exe' --path . --script tools/verify_teaching_world.gd -- --capture
& 'D:\Research\GameDevelopment\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script scenes/teaching_building/verify_movement.gd
```

场景往返、人物尺寸和碰撞体、时间连续性、太阳方向、昼夜亮度与实际输入移动检查通过。步行一秒实测 3.99995 米，Shift 奔跑一秒实测 7.20016 米。既有五层楼梯上下行验证通过。

同一走廊机位的实际 Forward+ 渲染截图：`corridor_09.png`、`corridor_12.png`、`corridor_15.png`、`corridor_00.png`。运行检查时引擎仍报告空材质相关警告，未阻止测试与截图完成。

## 室内自由旋转与相机高度

教学楼使用 `scenes/teaching_building/indoor_camera.gd`，不使用建筑遮挡透明。相机水平和俯仰角不受室内限位，也不会在贴墙时被自动改写；只限制实际相机高度，并用球体扫掠与补充射线避开实墙、楼板。相机可以绕到走廊栏杆外侧，栏杆和楼梯扶手继续阻挡人物，但不参与相机碰撞。

走廊/楼梯区域权重沿横向和纵向连续变化，取消原先两套水平边界的硬切换。楼梯目标距离逐步收至 1.8 米，离开后平滑恢复；提前检测墙角，配合短暂保持和缓慢恢复，避免门口或栏杆附近突然收放。校正相机高度后仍对准人物，保留输入的轨道角度。

室内可请求的缩放范围为 1.2–5 米，实际距离按空间约束缩短。正式游戏通过 `configure_world` 切换策略；F6 测试场景也使用相同策略。回到校园会还原进入教学楼前的相机姿态、缩放和视野，校园原本的遮挡处理继续生效。

## 当前楼层小地图

室外小地图继续使用真实世界俯视相机。教学楼改用独立 `World3D` 中的共享网格副本，应用 `indoor_minimap.gdshader`，只渲染当前楼层地面到 2.4 米的剖切范围，以斜俯视显示墙面、走廊和楼梯。地图单独使用简明配色，主场景材质、灯光、透明度不受影响。楼层编号显示为 1F–5F；楼梯平台附近使用高度滞后，防止编号来回跳。地图朝向只跟随水平旋转，不会因仰俯越过头顶而跳转。

`tools/verify_teaching_camera.gd` 检查五层走廊、两处楼梯的入口、上下跑与平台，共 3,717 组位置/角度组合；另检查两处入口三个朝向的往返连续路径、栏杆外侧取景、自由鼠标旋转、五层地图、上下楼层剖切以及场景往返恢复。图形模式生成 `camera_floor_1.png`、`camera_floor_3.png`、`camera_floor_5.png` 及对应的 `minimap_floor_*.png`。
