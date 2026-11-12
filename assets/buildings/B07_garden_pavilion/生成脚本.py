import bpy, math, os
from mathutils import Vector
out=r'D:\Research\GameDevelopment\建模\B07_garden_pavilion'
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=24
scene.cycles.use_denoising=True
scene.render.resolution_x=1200;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('World')

def mat(name,color,rough=.7,alpha=1):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,alpha);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Alpha'].default_value=alpha
 if alpha<1: m.surface_render_method='DITHERED'
 return m

def texmat(name):
 m=mat(name,(1,1,1)); n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(os.path.join(out,name+'.png'));n.image.pack();n.interpolation='Closest';m.node_tree.links.new(n.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color']);return m
wall=texmat('wall');roof=texmat('roof');floor=texmat('floor'); ivory=mat('暖白石材',(0.8,.78,.74));trim=mat('屋檐浅蓝金属',(.65,.78,.82),.4); frame=mat('蓝灰窗框',(.25,.39,.43),.38);glass=mat('透明蓝玻璃',(.29,.65,.75),.16,.22); dark=mat('花池土壤',(.19,.15,.11));green=mat('绿植',(.19,.42,.12)); green2=mat('绿植高光',(.36,.58,.17)); flower=mat('花朵',(.85,.43,.58))

def uv(o):
 mesh=o.data; layer=mesh.uv_layers.new(name='Metric')
 for poly in mesh.polygons:
  normal=poly.normal
  for li in poly.loop_indices:
   v=mesh.vertices[mesh.loops[li].vertex_index].co+o.location
   if abs(normal.z)>=max(abs(normal.x),abs(normal.y)): co=(v.x/4,v.y/4)
   elif abs(normal.y)>=abs(normal.x): co=(v.x/4,v.z/4)
   else: co=(v.y/4,v.z/4)
   layer.data[li].uv=co

def box(name,loc,size,material,bevel=0):
 x,y,z=size;verts=[(a*x/2,b*y/2,c*z/2) for a,b,c in [(-1,-1,-1),(-1,-1,1),(-1,1,-1),(-1,1,1),(1,-1,-1),(1,-1,1),(1,1,-1),(1,1,1)]]
 faces=[(0,4,6,2),(1,3,7,5),(0,1,5,4),(2,6,7,3),(0,2,3,1),(4,5,7,6)]
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);scene.collection.objects.link(o);o.location=loc;o.data.materials.append(material);uv(o)
 if bevel:
  mod=o.modifiers.new('轻微倒角','BEVEL');mod.width=bevel;mod.segments=1
  mod2=o.modifiers.new('加权法线','WEIGHTED_NORMAL')
 return o

def facade(y,front=True):
 # Each wing built around actual openings.
 for s in (-1,1):
  centers=[s*5.05,s*6.0,s*6.95]; intervals=sorted([(c-.29,c+.29) for c in centers]);start=-8 if s<0 else 4
  end=-4 if s<0 else 8
  for lo,hi in intervals:
   if lo>start:box('正面窗间墙',((lo+start)/2,y,1.8925),(lo-start,.22,2.165),wall)
   start=hi
  if end>start:box('正面窗间墙',((end+start)/2,y,1.8925),(end-start,.22,2.165),wall)
  for c in centers:
   box('侧翼玻璃',(c,y,1.9),(.54,.035,2.15),glass)
   box('窗槛',(c,y-.05,0.8),(.65,.3,.1),ivory)
   box('窗中横档',(c,y-.13,1.75),(.58,.08,.06),frame)
  box('侧翼窗上墙',(s*6,y,3.2675),(4,.22,.585),wall)
  box('侧翼上窗',(s*6,y,3.72),(3.7,.035,.32),glass)
  for c in [s*4.6,s*5.3,s*6,s*6.7,s*7.4]:box('上窗竖框',(c,y-.12,3.72),(.08,.07,.34),frame)
  box('侧翼窗下墙',(s*6,y,.66),(4,.22,.3),wall)
 # Center curtain wall, vertical + horizontal mullions separated from glass
 box('大厅玻璃',(0,y,2.12),(7.9,.035,3.18),glass)
 for i in range(9):box('幕墙竖框',(-3.92+i*.98,y-.09,2.12),(.065,.08,3.2),frame)
 for z in (.53,1.45,2.43,3.4,3.72):box('幕墙横框',(0,y-.095,z),(7.9,.085,.065),frame)
 box('入口门框上',(0,y-.15,2.18),(2.35,.1,.09),ivory)
 for x in (-1.16,0,1.16):box('入口门框',(x,y-.15,1.35),(.07,.1,1.66),ivory)
facade(-3.8);facade(3.8,False)
# side walls with genuine openings
for x in (-7.89,7.89):
 centers=[-2.9,-1.45,0,1.45,2.9];prev=-3.69
 for c in centers:
  lo,hi=c-.32,c+.32
  if lo>prev:box('山墙窗间墙',(x,(prev+lo)/2,1.8925),(.22,lo-prev,2.165),wall)
  box('山墙窗玻璃',(x,c,1.9),(.03,.6,2.15),glass)
  box('山墙窗横框',(x,c,1.7),(.3,.6,.06),frame)
  prev=hi
 if prev<3.69:box('山墙窗间墙',(x,(prev+3.69)/2,1.8925),(.22,3.69-prev,2.165),wall)
 box('山墙下墙',(x,0,.65),(.22,7.38,.3),wall);box('山墙上墙',(x,0,3.4475),(.22,7.38,.945),wall)
box('基座',(0,0,.22),(16.4,8.2,.44),ivory,.05)
box('大厅地面',(0,0,.46),(15.55,7.35,.04),floor)
# Interior: lobby furniture and planters, open view through glazing.
for x in (-5,5):
 box('室内花槽',(x,1.6,.72),(1.25,.65,.5),ivory,.035)
 for dx in (-.35,0,.35):
  box('室内植物',(x+dx,1.6,1.11),(.28,.3,.3),green2,.05)
for z,dim in [(3.92,(16.3,8.3,.15)),(4.06,(16.55,8.55,.13))]:box('连续屋檐',(0,0,z),dim,trim,.035)
# hip roof solid, ridge aligned long axis
verts=[(-8.25,-4.25,4.13),(8.25,-4.25,4.13),(8.25,4.25,4.13),(-8.25,4.25,4.13),(-1.9,0,5.85),(1.9,0,5.85)]
faces=[(0,1,5,4),(1,2,5),(2,3,4,5),(3,0,4),(3,2,1,0)]
me=bpy.data.meshes.new('四坡屋顶');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new('四坡屋顶',me);scene.collection.objects.link(o);me.materials.append(roof);uv(o)
box('屋脊',(0,0,5.88),(3.95,.18,.1),trim,.025)
# broad entrance stairs, each contiguous
for i in range(4):box('入口台阶',(0,-4.28-i*.3,.4-i*.1),(5.0,.3,.12),ivory,.015)
# exterior planters front
for x in (-6,6):
 box('花池',(x,-4.13,.4),(3.5,.6,.4),ivory,.035)
 box('花池土',(x,-4.13,.62),(3.25,.47,.04),dark)
 for j in range(8):
  xx=x-1.42+j*.4
  box('灌木',(xx,-4.13,.77),(.33,.38,.27),green if j%2 else green2,.07)
  if j%3==0:box('花',(xx,-4.34,.82),(.12,.08,.12),flower,.025)
# lighting and camera
world=scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.27,.29,.34,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
bpy.ops.object.light_add(type='AREA',location=(-8,-12,18));light=bpy.context.object;light.name='柔光';light.data.energy=2200;light.data.shape='DISK';light.data.size=12
bpy.ops.object.camera_add(location=(21,-30,16));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,2.2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=22.4;scene.camera=cam
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=os.path.join(out,'B07_预览.png')
tris=0
dg=bpy.context.evaluated_depsgraph_get()
for obj in scene.objects:
 if obj.type=='MESH':
  ev=obj.evaluated_get(dg);m=ev.to_mesh();m.calc_loop_triangles();tris+=len(m.loop_triangles);ev.to_mesh_clear()
print('TRIANGLES',tris)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'B07_garden_pavilion.blend'))
bpy.ops.render.render(write_still=True)


