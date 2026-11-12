import bpy,math
from pathlib import Path
from mathutils import Vector
out=Path(r'D:\Research\GameDevelopment\建模\P06_plaza_lamp')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,c,metal,rough,em=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if em:p.inputs['Emission Color'].default_value=(*c,1);p.inputs['Emission Strength'].default_value=em
 return m
gold=mat('Warm gold',(.63,.32,.055),.75,.3);glass=mat('Warm ivory glass',(1,.67,.35),0,.38,.15)
def box(n,loc,dim):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(gold);mod=o.modifiers.new('Bevel','BEVEL');mod.width=.014;mod.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
def bar(n,a,b,r,verts=8):
 a,b=Vector(a),Vector(b);v=b-a;bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=v.length,location=(a+b)/2);o=bpy.context.object;o.name=n;o.rotation_euler=v.to_track_quat('Z','Y').to_euler();o.data.materials.append(gold)
def bulb(x,y,z):
 # faceted flame silhouette via lathed mesh
 rings=[(.025,.01),(.10,.04),(.16,.15),(.15,.28),(.08,.40),(.008,.49)];verts=[];faces=[];N=10
 for rad,zz in rings:
  for i in range(N):
   a=2*math.pi*i/N;verts.append((x+rad*math.cos(a),y+rad*math.sin(a),z+zz))
 for j in range(len(rings)-1):
  for i in range(N): faces.append((j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i))
 faces.append(tuple(reversed(range(N))));faces.append(tuple((len(rings)-1)*N+i for i in range(N)))
 mesh=bpy.data.meshes.new('Flame globe');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Flame globe',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(glass)
box('Bottom plinth',(0,0,.06),(.8,.8,.12));box('Upper plinth',(0,0,.17),(.64,.64,.10))
bar('Pedestal',(0,0,.23),(0,0,.72),.19,8);bar('Column shaft',(0,0,.70),(0,0,3.9),.095,10)
for z in (.72,.85,1.45,2.05,2.65,3.35,3.8):bar('Ornamental ring',(0,0,z),(0,0,z+.07),.13,10)
bar('Central lantern stem',(0,0,3.85),(0,0,4.65),.055);bar('Central cup',(0,0,4.61),(0,0,4.72),.14);bulb(0,0,4.72)
for i in range(6):
 a=i*2*math.pi/6;r=.68;x=r*math.cos(a);y=r*math.sin(a);z=4.12+(i%2)*.30
 # stepped arms approximate ornamental sweep
 bar('Arm lower',(0,0,3.68),(.34*math.cos(a),.34*math.sin(a),3.72),.045)
 bar('Arm rising',(.34*math.cos(a),.34*math.sin(a),3.72),(x,y,z-.12),.038)
 bar('Lantern cup',(x,y,z-.13),(x,y,z),.12);bulb(x,y,z)
scene=bpy.context.scene;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.08,.16,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
for loc,power in [((0,-5,7),1000),((4,3,6),800)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=5;o.rotation_euler=(Vector((0,0,2.5))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(7,-10,6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,2.6))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=6.2;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=800;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'P06_preview.png')
tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in scene.objects if o.type=='MESH')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'P06_plaza_lamp.blend'));bpy.ops.render.render(write_still=True)
(out/'检查说明.txt').write_text('P06 广场灯\n三角面数：%d\n按参考图估算高度约 5.2 m；含 7 灯罩、灯臂和柱座。\n状态：初稿。材质为 PBR 纯色，尚无像素风贴图或法线贴图；灯臂花纹较参考图简化。需复查灯体接头、360 度视图及游戏引擎导入。\n'%tris,encoding='utf-8');print('TRIS',tris)
