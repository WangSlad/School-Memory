# 春日和风 · 轻复古校园：原教学楼五层材质

已直接接入 `scenes/teaching_building/teaching_building.tscn` 使用的建筑脚本，默认对原五层教学楼启用统一材质、分层门牌、实体外墙收口和精细木制门窗。原一层样板保留作材质参考。

## 查看结果

在 Godot 中打开 `res://scenes/teaching_building/teaching_building_test.tscn`，按 F6。此场景保留原角色和检查相机，使用暖色天空、太阳与一盏不投影的方向反弹光。主建筑组件中的材质也会在其他实例化位置生效；本次午后灯光配置位于原测试场景中。

原五层走廊地面跨度为 **4.8 米**，没有调整。一层样板采用原有单层模型，走廊跨度为 **2.4 米**，因此两者看起来不同，不能将差异全部归因于视角。五层仍保留 4.32 米层高、10.4 米开间和全部原网格变换。

最终实际渲染截图位于 `docs/teaching_spring_review/`：

| 截图 | 内容 |
| --- | --- |
| `five_corridor_f1.png`、`five_corridor_f3.png`、`five_corridor_f5.png` | 第一、三、五层走廊与对应门牌 |
| `five_facade.png` | 五层整体立面 |
| `five_window_support.png` | 门窗背衬、窗台凸台、实体墙裙近景 |
| `five_stair_left.png` | 左侧楼梯入口及未被墙裙封闭的洞口 |
| `five_original_same_camera.png` | 同一五层模型、灯光与相机下关闭新材质和收口后的对照 |
| `five_render.log` | D3D12 / Forward+ 实际渲染日志 |

## 文件与贴图

| 文件 / 目录 | 用途 |
| --- | --- |
| `tools/generate_teaching_spring_textures.py` | 固定种子的 NumPy / Pillow 贴图生成器 |
| `assets/buildings/teaching_floor/spring/textures/` | 21 张 1024×1024 PNG，单层与五层共享 |
| `assets/buildings/teaching_floor/spring/materials/` | 13 种共享材质角色，区分木窗框/金属栏杆与窗玻璃/栏杆玻璃 |
| `assets/buildings/teaching_floor/spring/shaders/` | 墙面及带门牌烤漆门着色器 |
| `assets/buildings/teaching_floor/spring/spring_materials.gd` | 材质槽映射、楼层图集、平铺尺度适配，可恢复原槽 |
| `scenes/teaching_building/teaching_building.gd` | 原五层建筑入口，默认应用新材质与外墙收口 |
| `scenes/teaching_building/facade_relief.gd` | 与原墙相连的实体墙裙、压顶、踢脚、门窗套背衬、窗台 |
| `scenes/teaching_building/teaching_building_test.tscn`、`inspection_lighting.gd` | 原测试场景中的午后光照配置 |
| `tools/verify_teaching_five_spring.gd` | 原网格、物理、门牌、五层收口回归检查 |
| `tools/verify_teaching_spring.gd` | 单层材质共享、恢复、实例隔离检查 |
| `tools/capture_teaching_building.gd` | 加载原测试场景进行最终截图，临时相机仅存在于截图运行中 |

外部素材按原有编号与语义命名习惯归档到：

`D:\Research\GameDevelopment\视图\平面素材\B03_teaching_spring\`

该目录包含与项目字节一致的 21 张纹理及一张色板预览。例如 `B03_teaching_spring_wall_平面.png`、`B03_teaching_spring_floor_normal.png`、`B03_teaching_spring_floor_roughness.png`。新增五层门牌为 `B03_teaching_spring_sign_five_平面.png`，5 列 × 8 行，编号 `1-01` 至 `5-08`；原单层门牌图集仍保留。

## 材质与实体收口

原单层及五层 GLB 均没有 UV，采用世界空间三平面映射。墙面暖象牙白 #F1EDE5、地砖暖石灰 #C7C1B5、门深灰绿 #596D68、框与栏杆灰绿 #748680、混凝土浅暖灰 #D5D0C7、墙裙灰樱粉 #D7A8AF、门牌麦芽黄 #D9BD7B。栏杆玻璃使用 #A9BBC2 透明材质，Alpha 0.30、粗糙度 0.24；教室窗改为不透明雾蓝反射玻璃，阻止未建模内部空壳穿透。门与窗框使用新增的低饱和漆面木纹，栏杆仍保留金属材质。

墙面、地砖和混凝土补充轻法线与粗糙度，涂料保持细颗粒。五层地砖映射对应原有被拉伸后的约 0.78×1.2 米砖缝；单层保持 0.6 米网格。所有纹理启用 VRAM 压缩、mipmap 与各向异性过滤，法线按 Normal Map 导入。门牌只出现在八个教室开间，办公室、厕所不误用教室编号；门牌固定于原门高范围内，按楼层独立取样。

根据后续关于悬空饰面的要求，局部增加闭合实体收口，保留原 GLB / Blend：

- 原框背距墙约 4 厘米，以略宽的混凝土背衬嵌入墙面并连接原框；背衬前端为 z=0.060 米，避开原门面/玻璃 z=0.065 米的共面闪烁。
- 窗下增加嵌墙凸台，前端 z=0.245 米，顶面精确接到原横框下缘。
- 樱粉墙裙有实际厚度，带浅暖灰压顶和踢脚，门洞与两个楼梯洞口保持畅通。
- 每层 269 个盒体轮廓按材质合并为 2 个共享 ArrayMesh，重复到五层，共 10 个 MeshInstance3D。没有逐盒创建场景节点。

原表面共享 9 种材质角色；连同樱粉收口、木门压条、五金和密封缝，共 13 种。墙、门以及五层地砖仅按建筑实例复制需要参数的材质，重复网格共享该实例资源。五层采用实体墙裙时关闭墙着色器中的平面粉色条带。

新收口在全部原碰撞和楼层接口创建后加入，不添加物理节点。原模型文件、检查相机、角色控制和角色相机 SHA256 与修改前一致。建筑整体结构、104 个原碰撞体、40 个教室接口与控制逻辑保持原样。渲染设置只在教学楼测试场景应用，没有修改项目全局渲染设置。

## 复现与检查

在项目根目录运行（需要 Python、Pillow、NumPy）：

```powershell
python tools/generate_teaching_spring_textures.py
python tools/generate_teaching_joinery_textures.py
# 仅生成新增的五层门牌，不重写其余贴图：
python tools/generate_teaching_spring_textures.py --sign-five-only
```

默认同时更新项目纹理目录与上述外部素材目录。可用 `--output` 和 `--archive` 指定其他目录。

```powershell
$godotExe = 'D:\Research\GameDevelopment\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path . --editor --import
& $godotExe --headless --path . --script res://tools/verify_teaching_five_spring.gd --quit-after 120
& $godotExe --headless --path . --script res://tools/verify_teaching_spring.gd --quit-after 120
& $godotExe --headless --path . --script res://scenes/teaching_building/verify_collisions.gd
& $godotExe --headless --path . --script res://scenes/teaching_building/verify_movement.gd
& $godotExe --headless --path . --script res://scenes/teaching_building/verify_left_stair.gd
& $godotExe --path . --resolution 1600x900 --script res://tools/capture_teaching_building.gd
```

2026-11-13 验证结果：

- 21 张纹理全部为 1024×1024 PNG，与外部归档字节一致；新增 5 张木纹/门面纹理在临时目录重跑后与项目纹理字节一致。
- 周期纹理边界统计通过；门牌图集为刻意不平铺的独立图集。
- `FIVE_SPRING_OK source_meshes=142 shared_materials=9 corridor_width=4.8 colliders=104 original_structure=yes old_handle_render_replaced=yes identical_physics=yes solid_profiles_per_floor=269`。
- `SPRING_MATERIALS_OK meshes=659 shared_materials=9 restoration=ok isolation=ok`。
- `FLOOR_RAIL_WALL_OK floors=5`；左右楼梯分别 `ASCENT_OK`、`DESCENT_OK`，均为 40 教室、104 碰撞体。
- Godot 4.7.2 / RTX 4060 Laptop / D3D12 / Forward+ 已实际渲染第一、三、五层走廊、整体立面、凸台近景、左楼梯及原材质对照，退出码 0，日志无脚本和着色器错误。


## 追加改进：透明显示与精细门窗（2026-11-13）

针对“空心/透明”反馈，已对源 GLB 逐网格按位置焊接、统计边界与有符号体积。原五层 838 个几何组件全部封闭、朝外，未发现开边或反向法线。主要问题是前次将原本 OPAQUE 的窗玻璃映射为双面透明，使没有教室隔墙的内部空壳显露；合并为整排的透明盒体又会产生排序及双层混色。具体报告为 `docs/teaching_spring_review/mesh_audit.json`，复现脚本为 `tools/audit_teaching_meshes.py`。报告同时记录旧单层源模型法线朝内；当前五层源模型已正确朝外，不应整体翻面。

修复采用独立的不透明雾蓝窗玻璃，保留柔和天空反射；这不是完整教室室内建模。栏杆保持通透，原合并玻璃仅隐藏渲染，以 `glazing_panels.gd` 创建 75 块按位置独立排序的封闭玻璃面板，正常背面剔除、关闭玻璃投影，避免同一盒体的前后面重复混色。三个 BoxMesh 在各层复用，原玻璃碰撞完整保留。

`joinery_detail.gd` 为五层共 95 扇门、110 组窗增加倒角实体：门嵌板压条、门止口、三组合页、镍色拉手与背板、螺钉槽、下沿护板；窗有双扇压条、密封缝、上下错位的窗扇层次、可见滑轨和中央锁扣。旧粗方块门把手的五个源渲染组被隐藏，原网格资源和物理不变。新增 4 个闭合细节网格在五层重复，仅创建 20 个细节渲染节点，共约 26.25 万三角形；外墙收口另有原先的 10 个渲染节点。`joinery_detail_enabled` 可控制这些新构件。

新增生成器 `tools/generate_teaching_joinery_textures.py` 生成 5 张 PNG：`door_wood_平面`、`frame_wood_平面`、`wood_normal`、`wood_roughness`、`door_panel_平面`，均带 `B03_teaching_spring_` 前缀。木纹、法线、粗糙度可无缝平铺，门面图按 1.3×2.35 米整扇映射，顶部留门牌。新贴图全部启用实际 VRAM 导入及 mipmap，并同步外部素材归档。

新增检查：

```powershell
python tools/audit_teaching_meshes.py
& $godotExe --headless --path . --script res://tools/verify_teaching_joinery.gd --quit-after 120
```

结果：`JOINERY_OK closed_bevelled_profiles_per_floor=1193 shared_meshes=4 nodes=20 doors=95 windows=110 triangles_per_floor=52492 window_opaque=yes railing_independent_panes=75 boundary_edges=0 colliders=104`。还验证了原结构、网格资源、变换、所有碰撞形状和左右楼梯通行。新增实机截图为 `five_door_detail.png`、`five_window_detail.png`、`five_glass_layers.png`、`five_underside.png`；最终日志 `five_joinery_render.log`。早一版本走廊/窗台截图保留于 `before_joinery/` 供对照。

后续房间布局已更新：每层最右侧原办公室改为男左女右两间卫生间，新增门标PNG后共22张贴图，局部碰撞更新为109个。上述104个碰撞体结果为改造前材质阶段基线，当前结果详见 [卫生间改造说明](teaching_restrooms.md)。
