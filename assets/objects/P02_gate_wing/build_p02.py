import bpy,math
from pathlib import Path
from mathutils import Vector
out=Path(r'D:\Research\GameDevelopment\建模\P02_gate_wing')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(n,c,metal=0,rough=.6):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
stone=mat('Pale stone',(.72,.70,.70)); steel=mat('Steel',(.52,.59,.62),.65,.35); blue=mat('Blue railing',(.07,.23,.35),.55,.35);canvas=mat('Ivory canopy',(.85,.87,.89),0,.85)
def box(n,loc,dim,m,bev=.01):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if bev:
  mod=o.modifiers.new('Edge bevel','BEVEL');mod.width=bev;mod.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
def bar(n,a,b,r,m,verts=6):
 a,b=Vector(a),Vector(b);v=b-a;bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=v.length,location=(a+b)/2);o=bpy.context.object;o.name=n;o.rotation_euler=v.to_track_quat('Z','Y').to_euler();o.data.materials.append(m)
def canopy(x0,x1):
 # faceted tensile roof, front and back in a closed double-sided shell
 verts=[(x0,-.55,1.73),(x1,-.55,1.73),(x1,.55,1.73),(x0,.55,1.73),((x0+x1)/2,0,2.01)]
 verts += [(x,y,z-.025) for x,y,z in verts]
 faces=[]
 for i in range(4):
  j=(i+1)%4;faces.extend([(i,j,4),(5+j,5+i,9),(i,5+i,5+j,j)])
 mesh=bpy.data.meshes.new('Faceted canopy');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Tensile canopy bay',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(canvas)
w=12; n=6; step=w/n
box('Foundation',(0,0,.06),(12.4,1.35,.12),stone,.02)
for i in range(n+1):
 x=-w/2+i*step
 box('Pier',(x,0,.83),(.30,1.05,1.48),stone,.015)
 box('Pier cap',(x,0,1.63),(.39,1.14,.12),stone,.015)
 bar('Mast',(x,.34,1.69),(x,.34,3.05),.045,steel,8)
bar('Canopy front rail',(-w/2,-.55,1.70),(w/2,-.55,1.70),.035,steel,6)
bar('Canopy rear rail',(-w/2,.55,1.70),(w/2,.55,1.70),.035,steel,6)
for i in range(n):
 a=-w/2+i*step+.18;b=-w/2+(i+1)*step-.18
 box('Blue panel',( (a+b)/2,0,1.04),(b-a,.09,.75),blue,.006)
 for x in [a+(b-a)*j/12 for j in range(1,12)]:bar('Vertical grille',(x,-.065,.70),(x,-.065,1.38),.013,steel,4)
 bar('Upper rail',(a,-.07,1.39),(b,-.07,1.39),.02,steel,6)
 bar('Lower rail',(a,-.07,.68),(b,-.07,.68),.02,steel,6)
 canopy(-w/2+i*step,-w/2+(i+1)*step)
 x=-w/2+i*step
 bar('Cable',(x,.34,3.01),(x+step/2,-.55,1.73),.012,steel,4)
 bar('Cable',(x+step,.34,3.01),(x+step/2,-.55,1.73),.012,steel,4)
scene=bpy.context.scene;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.08,.16,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
for loc,power in [((0,-8,9),2200),((6,5,7),1500)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=8;o.rotation_euler=(Vector((0,0,1.2))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(12,-20,9));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.3))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=15;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=1400;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'P02_preview.png')
tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in scene.objects if o.type=='MESH')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'P02_gate_wing.blend'));bpy.ops.render.render(write_still=True)
(out/'检查说明.txt').write_text('P02 校门侧翼\n三角面数：%d\n按参考图估算总宽约 12 m。\n状态：初稿；含 6 跨护栏、砌体柱、桅杆、索及张拉顶棚，花坛植物未制作。\n纯色 PBR 材质；缺少像素贴图、法线图及 UV 检查。需复核连接处、所有角度与游戏引擎表现。\n'%tris,encoding='utf-8');print('TRIS',tris)
