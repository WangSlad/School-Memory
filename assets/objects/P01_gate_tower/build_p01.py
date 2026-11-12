import bpy,math
from pathlib import Path
from mathutils import Vector
out=Path(r'D:\Research\GameDevelopment\建模\P01_gate_tower')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(n,c,metal=0,rough=.6):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
stone=mat('Pale stone',(.72,.69,.69));glass=mat('Opaque blue glazing',(.045,.20,.31),.45,.26);metal=mat('Blue-gray frames',(.16,.24,.28),.6,.3)
def box(n,loc,dim,m,bev=.01):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if bev:
  mod=o.modifiers.new('Bevel','BEVEL');mod.width=bev;mod.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
box('Stone mass',(0,.20,2.87),(3.9,2.5,5.74),stone,.03)
box('Base plinth',(0,0,.14),(4.4,3.05,.28),stone,.025)
box('Front glass panel',(0,-1.057,2.84),(2.55,.035,4.78),glass,.008)
for x in [-1.275,-.6375,0,.6375,1.275]:box('Window mullion',(x,-1.082,2.84),(.05,.06,4.83),metal,.004)
for i in range(7):
 z=.45+i*4.78/6;box('Window transom',(0,-1.085,z),(2.6,.06,.045),metal,.004)
box('Top louvre field',(0,-1.06,5.59),(2.55,.04,.45),glass,.005)
for i in range(7):box('Louvre',(0,-1.09,5.40+i*.06),(2.53,.055,.017),metal,.002)
box('Crown cornice',(0,.10,5.88),(4.1,2.85,.20),stone,.025)
box('Roof raised coping',(0,.15,6.06),(3.0,2.45,.18),stone,.02)
# joints are narrow inlaid grooves above the supporting side walls
for side in (-1,1):
 for z in [.65,1.35,2.05,2.75,3.45,4.15,4.85,5.55]:box('Stone joint',(side*1.59,-1.057,z),(.61,.012,.012),metal,0)
scene=bpy.context.scene;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.08,.16,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
for loc,power in [((0,-7,9),1500),((6,4,7),1200)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=7;o.rotation_euler=(Vector((0,0,3))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(9,-13,9));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,3))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=8.2;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=900;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'P01_preview.png')
tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in scene.objects if o.type=='MESH')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'P01_gate_tower.blend'));bpy.ops.render.render(write_still=True)
(out/'检查说明.txt').write_text('P01 校门柱楼\n三角面数：%d\n依据三视图估算 4.4 m 宽、6.15 m 高；楼体、窗框、顶冠独立。\n状态：初稿；窗户目前为不透明蓝色外墙，不含室内空间。原图窗景细节和周围花坛缺失，像素材质、法线和完整 360 度验证尚未制作；需要根据设计决定是否将窗改透明并建立内部。\n'%tris,encoding='utf-8');print('TRIS',tris)
