# 校门内外传送

主校门左右两段伸缩栅栏（`ChunhuiBuilding23`、`ChunhuiBuilding24`）各有内外一对交互点，位于 `world/campus.tscn` 的 `GateLeftInside/Outside` 与 `GateRightInside/Outside`。标记复用教学楼安全出口图案、0.75 米光圈和悬浮高亮效果，内侧提示“走出校门”，外侧提示“进入校园”。

`local_teleport_target` 指向当前场景中的对侧 `Marker3D`；`target_world_path` 留空。`core/game_root.gd` 的 `_teleport_to()` 直接设置人物变换并清零速度，等待物理识别区更新后恢复输入。不会重新加载校园、发出 `world_changed` 或重置小地图与时间。抵达后可再次按 E 返回。

内外两侧 Z 分别为 34.65、37.45，避开位于 Z=36.052887 的栅栏；左右 X 分别为 -22.405455、-8.607754。相应 `Gate*Spawn` 标记用于控制落点与人物朝向。

验证：`godot --headless --path . --script tools/verify_gate_teleport.gd`。图形模式加 `-- --capture` 输出 `docs/teaching_world_review/gate_teleport.png`。测试覆盖实际 E 键分发、四个方向的落点与交互可用性、落地检查，以及场景实例、时间、相机和小地图保持不变。
