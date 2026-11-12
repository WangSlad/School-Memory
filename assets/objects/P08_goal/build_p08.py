import bpy, math
from mathutils import Vector
from pathlib import Path
out=Path(r'D:\Research\GameDevelopment\建模\P08_goal')
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def material(name,col,metal=0,rough=.45):
 m=bpy.data.materials.new(name); m.diffuse_color=(*col,1); m.use_nodes=True; p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*col,1); p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=rough; return m
white=material('Powder coated off-white',(0.81,.84,.85),.25,.32)
net=material('Pale nylon rope',(.65,.70,.72),0,.75)
foot=material('Footplate',(.50,.55,.58),.6,.35)
def bar(name,a,b,r,mat,verts=8):
 a,b=Vector(a),Vector(b); delta=b-a
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=delta.length,end_fill_type='NGON',location=(a+b)/2)
 o=bpy.context.object; o.name=name; o.rotation_euler=delta.to_track_quat('Z','Y').to_euler(); o.data.materials.append(mat); return o
def box(name,loc,scale,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object;o.name=name;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat); bevel=o.modifiers.new('Small edge bevel','BEVEL');bevel.width=.008;bevel.segments=1;bevel.affect='EDGES';bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=bevel.name);return o
# goal mouth at y=-0.85; rear net at y=0.85
w=6.0; h=2.35; d=1.7
for x in (-w/2,w/2):
 bar('Upright',(x,-d/2,.06),(x,-d/2,h),.065,white,12)
 bar('Rear support',(x,d/2,.06),(x,d/2,h-.20),.048,white,10)
 bar('Ground return',(x,-d/2,.06),(x,d/2,.06),.046,white,10)
 bar('Top return',(x,-d/2,h),(x,d/2,h-.20),.046,white,10)
 box('Mount plate',(x,-d/2,.025),(.30,.23,.05),foot)
bar('Crossbar',(-w/2,-d/2,h),(w/2,-d/2,h),.065,white,12)
bar('Rear upper rail',(-w/2,d/2,h-.20),(w/2,d/2,h-.20),.042,white,10)
bar('Rear lower rail',(-w/2,d/2,.06),(w/2,d/2,.06),.042,white,10)
# Continuous, non-coplanar nylon strands; 4-sided section conserves triangles.
for i in range(1,25):
 x=-w/2+w*i/25
 bar('Net rear vertical',(x,d/2-.012,.08),(x,d/2-.012,h-.22),.009,net,4)
 bar('Net roof lengthwise',(x,-d/2+.03,h-.014),(x,d/2-.02,h-.214),.009,net,4)
for j in range(1,10):
 z=.06+(h-.26)*j/10
 bar('Net rear horizontal',(-w/2+.02,d/2+.012,z),(w/2-.02,d/2+.012,z),.009,net,4)
 for x in (-w/2+.01,w/2-.01):
  bar('Net side horizontal',(x,-d/2+.03,z),(x,d/2-.03,z),.009,net,4)
for i in range(1,7):
 y=-d/2+d*i/7
 ztop=h-.2*i/7
 for x in (-w/2+.01,w/2-.01): bar('Net side vertical',(x,y,.08),(x,y,ztop-.02),.009,net,4)
 bar('Net roof crosswise',(-w/2+.02,y,ztop+.01),(w/2-.02,y,ztop+.01),.009,net,4)
# Turntable lighting and camera; no ground geometry included in asset.
scene=bpy.context.scene
scene.world.color=(.16,.16,.16)
world=scene.world; world.use_nodes=True; world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.08,.16,1);world.node_tree.nodes['Background'].inputs[1].default_value=.8
def area(loc,power,size):
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
area((0,-6,9),1500,8);area((4,3,6),1100,7)
bpy.ops.object.camera_add(location=(8,-12,7));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=8.7;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=1200;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(out/'P08_preview.png')
scene.view_settings.view_transform='AgX'
meshes=[o for o in scene.objects if o.type=='MESH']; tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'P08_goal.blend'))
bpy.ops.render.render(write_still=True)
(out/'检查说明.txt').write_text('P08 足球门\n几何三角面数：%d\n尺寸：6.0 × 1.7 × 2.35 m（参考图无比例，按图估计）\n已建：门框、底部回撑、顶部回撑、真实网绳、底板；灯光及相机用于预览。\n材质：纯色 PBR 材质，尚未制作像素美术贴图、法线贴图或 UV 检查。\n待检查：360 度人工检查、网绳交接、几何重叠和游戏引擎导入；网绳交织为几何穿插。\n状态：初稿，未达到全部验收要求。\n'%tris,encoding='utf-8')
print('TRIS',tris)

