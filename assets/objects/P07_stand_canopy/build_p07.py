import bpy,math
from pathlib import Path
from mathutils import Vector
out=Path(r'D:\Research\GameDevelopment\建模\P07_stand_canopy')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(n,c,metal=0,rough=.6):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
stone=mat('Concrete',(.68,.67,.66));steel=mat('Steel',(.66,.70,.71),.65,.4);blue=mat('Blue plastic seating',(.015,.19,.52),.05,.3);canvas=mat('Ivory membrane',(.82,.84,.88));glass=mat('Opaque tinted glazing',(.08,.24,.29),.4,.3)
def box(n,loc,dim,m,bev=.012):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if bev:
  mod=o.modifiers.new('Bevel','BEVEL');mod.width=bev;mod.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
def bar(n,a,b,r,m,verts=6):
 a,b=Vector(a),Vector(b);v=b-a;bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=v.length,location=(a+b)/2);o=bpy.context.object;o.name=n;o.rotation_euler=v.to_track_quat('Z','Y').to_euler();o.data.materials.append(m)
box('Main concrete block',(0,0,.65),(9,4,1.3),stone,.025)
box('Front dark glass',(0,-2.012,.65),(7.7,.025,.75),glass,.004)
for x in [-3.8,-2.85,-1.9,-.95,0,.95,1.9,2.85,3.8]:box('Glass frame',(x,-2.035,.65),(.04,.04,.8),steel,.002)
for r in range(5):
 y=-1.55+r*.72;top=1.42+r*.28
 box('Bleacher riser',(0,y,1.3+(top-1.3)/2),(8.8,.72,top-1.3),stone,.008)
 for c in range(17):
  x=-3.75+c*.47
  box('Seat',(x,y-.08,top+.055),(.37,.35,.11),blue,.015)
  box('Seat back',(x,y+.07,top+.22),(.37,.07,.30),blue,0)
for x in (-4.1,4.1):
 bar('Mast',(x,1.7,1.3),(x,1.7,6.5),.065,steel,10)
 bar('Roof front beam',(-4.3,-1.9,5),(4.3,-1.9,5),.045,steel,8) if x<0 else None
 bar('Roof side beam',(x,-1.9,5),(x,1.7,5),.04,steel,8)
 bar('Cable',(x,1.7,6.45),(x,-1.9,5),.018,steel,5)
 bar('Stair rail',(x,-1.7,1.75),(x,1.7,3.08),.025,steel,6)
for j in range(2):
 x0=-4.15+j*4.15;x1=x0+4.15
 verts=[(x0,-1.9,5),(x1,-1.9,5),(x1,1.7,5),(x0,1.7,5),((x0+x1)/2,0,5.65)]
 verts += [(x,y,z-.025) for x,y,z in verts];faces=[]
 for i in range(4):
  k=(i+1)%4;faces.extend([(i,k,4),(5+k,5+i,9),(i,5+i,5+k,k)])
 mesh=bpy.data.meshes.new('Canopy shell');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Canopy',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(canvas)
scene=bpy.context.scene;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.08,.16,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
for loc,power in [((0,-8,11),1800),((6,5,9),1600)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=7;o.rotation_euler=(Vector((0,0,3))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(12,-18,10));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,3))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=12.3;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=1200;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'P07_preview.png')
tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in scene.objects if o.type=='MESH')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'P07_stand_canopy.blend'));bpy.ops.render.render(write_still=True)
(out/'检查说明.txt').write_text('P07 看台\n三角面数：%d\n估计宽 9 m；含台阶、85 个座椅、柱、屋顶与缆索。\n状态：初稿。底层窗为不透明板，无室内；缺少花坛、树木、细致桁架、像素贴图及法线，结构交接和 360 度未完成验证，需继续对照参考修正。\n'%tris,encoding='utf-8');print('TRIS',tris)

