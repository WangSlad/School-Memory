# 末端房间卫生间改造

已在原 `scenes/teaching_building/teaching_building.tscn` 中默认启用。打开同目录 `teaching_building_test.tscn` 按 F6 查看。

每层最右侧原办公室开间（bay13，x=135.2～145.6m）被改为两个独立卫生间。面向入口时男左女右，中间以16cm厚通高隔墙分开，新增左侧封墙，保留原后墙、右外墙、楼板和屋顶。相邻bay12与全部教室保持原样。走廊仍为4.8m，楼梯与角色逻辑未变。

- 男厕：独立门、2个带隔板厕位、2个小便器及隐私隔板、2个洗手台与镜子。
- 女厕：独立门、3个带隔板厕位、2个洗手台与镜子。
- 两扇入口门分别带男女图标、“男/女”和“MEN/WOMEN”标识；窗户提高为2.65～3.50m的雾蓝隐私高窗。
- 外立面保留暖象牙白、樱粉墙裙、灰绿木门窗；内部采用暖灰地砖与浅色易清洁墙裙。洁具带落地底座或嵌墙承托。
- 入口门与厕位门沿用当前建筑的静态关闭状态，未增加开门交互。内部实体已建好，检查截图由临时相机进入拍摄。

## 修改文件

| 文件 | 用途 |
| --- | --- |
| `scenes/teaching_building/restroom_conversion.gd` | 末端源立面局部替换、两间内部实体、局部碰撞与房间Marker接口 |
| `scenes/teaching_building/teaching_building.gd` | `restrooms_enabled=true`默认启用；先裁去旧末端立面，再生成匹配碰撞 |
| `scenes/teaching_building/facade_relief.gd` | 新卫生间启用时跳过旧末端收口 |
| `scenes/teaching_building/joinery_detail.gd` | 新两扇门及两组高窗对应的细节 |
| `assets/buildings/teaching_floor/spring/materials/restroom_*.tres` | 白墙、陶瓷与标识材质，复用其余现有材质 |
| `tools/generate_teaching_restroom_signs.py` | 可重跑1024²男女门标图集生成器 |
| `tools/verify_teaching_restrooms.gd` | 五层分隔、男女位置、局部网格改动范围及物理检查 |
| `tools/capture_teaching_restrooms.gd` | 原测试场景的入口、内部、洁具及临时剖顶截图 |

标识PNG为 `B03_teaching_spring_restroom_signs_平面.png`，保存在项目 `spring/textures/`，并同步到 `D:\Research\GameDevelopment\视图\平面素材\B03_teaching_spring\`。男列U=0～.5，女列U=.5～1；实际牌子.42×.62m。生成器固定输入和字体，重复运行输出字节一致。

## 局部替换与物理

原GLB、Blend不重写。仅六类合并网格创建运行时共享副本，去掉最右侧旧立面的三角形；保留bay12共享封盖及末端后/侧外墙。Godot导入资源去重后，每层替换314个三角形，五层共1570个；六份修订网格在五层复用。新卫生间按11种材质合并为11份共享网格，每层复用。

原104个静态碰撞体中，79个完全一致；25个相关源组仅重建与局部裁切匹配的形状，另外每层新增1个卫生间合并碰撞体，共109个。门、墙、隔板及主要洁具都有对应阻挡，旧门窗位置不残留原碰撞。40个教室接口、两组楼梯及全部走廊保留。

## 验证

```powershell
python tools/generate_teaching_restroom_signs.py
$godotExe = 'D:\Research\GameDevelopment\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path . --script res://tools/verify_teaching_restrooms.gd --quit-after 120
& $godotExe --path . --resolution 1600x900 --script res://tools/capture_teaching_restrooms.gd
```

2026-11-13结果：

- `RESTROOMS_OK floors=5 rooms=10 men_left=yes women_right=yes replacement_meshes=6 shared_room_meshes=11 colliders=109 unchanged_original_bodies=79 classrooms=40 corridor=4.8`。
- 原材质/门窗细节回归检查通过（在测试中关闭房间改造，独立核对原基线）。
- 五层地面、栏杆、墙面碰撞检查通过；左右楼梯均 `ASCENT_OK` / `DESCENT_OK`，40教室、109碰撞体。
- 男女标识1024×1024，VRAM压缩/mipmap导入、归档与可重复生成检查通过。
- 原模型源文件、角色与相机脚本SHA256与改造前一致。
- Godot 4.7.2 / D3D12 Forward+实际渲染成功，无脚本/着色器错误，日志 `docs/teaching_spring_review/five_restroom_render.log`。

截图位于 `docs/teaching_spring_review/`：`five_restrooms_f1.png`、`five_restrooms_f5.png`、`five_restroom_men.png`、`five_restroom_women.png`、`five_restroom_sinks.png`、`five_restroom_toilet.png`、`five_restroom_plan.png`。平面截图仅在截图脚本中临时隐藏顶层屋顶，生产场景屋顶完整。
