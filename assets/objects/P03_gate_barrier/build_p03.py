import bpy,math
from pathlib import Path
from mathutils import Vector
out=Path(r'D:\Research\GameDevelopment\建模\P03_gate_barrier')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,col,metal=.6,rough=.3):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
silver=mat('Brushed silver',(.63,.69,.72));dark=mat('Dark wheel rubber',(.12,.15,.17),.1,.65); stone=mat('Pale stone',(.63,.65,.67),.05,.75)
def box(n,loc,dim,m,bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if bevel:
  mod=o.modifiers.new('Bevel','BEVEL');mod.width=bevel;mod.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def bar(n,a,b,r,m,verts=4):
 a,b=Vector(a),Vector(b);v=b-a;bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=v.length,location=(a+b)/2);o=bpy.context.object;o.name=n;o.rotation_euler=v.to_track_quat('Z','Y').to_euler();o.data.materials.append(m);return o
box('Foundation',(0,0,.04),(7.2,.55,.08),stone)
for x in (-3.4,3.4):
 box('End foot',(x,0,.13),(.34,.35,.10),silver)
 box('End post',(x,0,.78),(.23,.23,1.22),silver)
 box('Post cap',(x,0,1.43),(.31,.31,.08),silver)
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.11,location=(x,0,1.58));bpy.context.object.name='Finial';bpy.context.object.data.materials.append(silver)
# scissor leaves alternate in front and behind, like a folding sliding gate
n=16; w=6.5
for i in range(n+1):
 x=-w/2+w*i/n
 box('Vertical link',(x,0,.78),(.045,.07,1.04),silver,0)
 box('Link cap',(x,0,1.34),(.09,.11,.06),silver,.008)
 bar('Wheel',(x,0,.16),(x,.12,.16),.072,dark,8)
for i in range(n):
 x0=-w/2+w*i/n;x1=-w/2+w*(i+1)/n
 bar('Scissor link A',(x0,-.045,.27),(x1,-.045,1.28),.018,silver,4)
 bar('Scissor link B',(x0,.045,1.28),(x1,.045,.27),.018,silver,4)
# Studio camera
scene=bpy.context.scene;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.08,.16,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
for loc,power in [((0,-5,8),1400),((4,3,5),1000)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=7;o.rotation_euler=(Vector((0,0,.8))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(8,-12,5));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=8.5;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=1200;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'P03_preview.png')
tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in scene.objects if o.type=='MESH')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'P03_gate_barrier.blend'));bpy.ops.render.render(write_still=True)
(out/'检查说明.txt').write_text('P03 伸缩门\n三角面数：%d\n根据参考图估算 7.2 m 宽；可伸缩外观为静态模型。\n状态：初稿。已制作端柱、折叠杆、滚轮及基座；用纯色金属材质，尚未制作像素贴图、法线或进行 UV 检查。\n待完成：完整 360 度核查、几何接头穿插修正和游戏引擎验证；细节、饰面与参考图仍有差距。\n'%tris,encoding='utf-8')
print('TRIS',tris)
