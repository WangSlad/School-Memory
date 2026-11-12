import bpy, math, os
from mathutils import Vector
out=r'D:\Research\GameDevelopment\建模\B04_repeated_block'
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


# Body: 8 bays, 5 floors; infill is transparent glazing with actual depth.
box('基座',(0,0,.2),(20.5,6.5,.4),ivory,.04)
for i in range(6):
 z=.4+i*2.3
 box('楼层板',(0,0,z),(20,6,.18),ivory,.025)
for flooridx in range(5):
 z=.4+flooridx*2.3
 # Thin floor spandrel and glazing on both long elevations
 for y in (-2.94,2.94):
  box('窗下墙',(0,y,z+.3),(20,.12,.42),wall)
  box('长窗玻璃',(0,y,z+1.32),(19.65,.035,1.62),glass)
  for x in [(-10+i*2.5) for i in range(9)]:
   box('立面竖向柱',(x,y,z+1.34),(.28,.3,1.8),ivory)
  for x in [(-8.75+i*2.5) for i in range(8)]:
   box('窗中央竖梃',(x,y-.09,z+1.33),(.055,.08,1.62),frame)
  box('窗横梃',(0,y-.1,z+1.3),(19.7,.07,.055),frame)
 # End walls with central window; no opaque block behind glazing.
 for x in (-9.94,9.94):
  box('侧墙前',(x,-1.95,z+1.34),(.12,2.1,1.8),wall)
  box('侧墙后',(x,1.95,z+1.34),(.12,2.1,1.8),wall)
  box('侧窗',(x,0,z+1.34),(.03,1.8,1.62),glass)
  box('侧窗下墙',(x,0,z+.265),(.12,5.76,.35),wall)
  box('侧窗竖梃',(x-.08,0,z+1.34),(.07,.06,1.62),frame)
# Simplified interior furnishing, visible through glazing.
for storey in range(5):
 for x in (-6,-2,2,6):
  box('室内桌面',(x,0,.99+storey*2.3),(1.3,.6,.09),ivory)
  for dx in (-.5,.5):box('桌脚',(x+dx,0,.73+storey*2.3),(.08,.45,.48),frame)
# Roof and raised rim
box('屋面',(0,0,12.02),(20.4,6.4,.24),roof,.04)
for y in (-3.1,3.1):box('女儿墙',(0,y,12.22),(20.4,.16,.2),ivory,.02)
for x in (-10.12,10.12):box('女儿墙',(x,0,12.22),(.16,6.05,.2),ivory,.02)
# entrance with canopy and stairs
box('入口雨棚',(0,-3.53,2.6),(5,.95,.2),ivory,.04)
for x in (-2.25,2.25):box('雨棚柱',(x,-3.88,1.48),(.2,.2,2.05),ivory,.02)
for x in (-1.12,0,1.12):box('门框',(x,-3.04,1.24),(.075,.1,1.65),frame)
for i in range(3):box('入口台阶',(0,-3.35-i*.32,.32-i*.1),(4.3,.32,.12),ivory,.02)
world=scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.27,.29,.34,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
bpy.ops.object.light_add(type='AREA',location=(-8,-12,22));light=bpy.context.object;light.data.energy=3000;light.data.shape='DISK';light.data.size=13
bpy.ops.object.camera_add(location=(25,-32,22));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,5.8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=27;scene.camera=cam
scene.render.filepath=os.path.join(out,'B04_预览.png')
dg=bpy.context.evaluated_depsgraph_get();tris=0
for obj in scene.objects:
 if obj.type=='MESH':
  ev=obj.evaluated_get(dg);m=ev.to_mesh();m.calc_loop_triangles();tris+=len(m.loop_triangles);ev.to_mesh_clear()
print('TRIANGLES',tris)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'B04_repeated_block.blend'))
bpy.ops.render.render(write_still=True)


