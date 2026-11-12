import bpy, math, os
from mathutils import Vector
out=r'D:\Research\GameDevelopment\建模\B05_red_roof'
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=12
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
wall=texmat('wall');roof=texmat('roof');floor=texmat('floor');grass=texmat('grass'); ivory=mat('暖白石材',(0.8,.78,.74));trim=mat('屋檐浅蓝金属',(.65,.78,.82),.4); frame=mat('蓝灰窗框',(.25,.39,.43),.38);glass=mat('透明蓝玻璃',(.29,.65,.75),.16,.22); dark=mat('花池土壤',(.19,.15,.11));green=mat('绿植',(.19,.42,.12)); green2=mat('绿植高光',(.36,.58,.17)); flower=mat('花朵',(.85,.43,.58))

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


# Two parallel wings and the link block form a courtyard open to the right.
def wing(name,cx,cy,w,d,n,bays):
 box(name+'基座',(cx,cy,.2),(w,d,.4),ivory,.025)
 for i in range(n+1):box(name+'楼板',(cx,cy,.4+i*2.1),(w,d,.12),ivory)
 for flooridx in range(n):
  z=.4+flooridx*2.1
  for y in (cy-d/2+.06,cy+d/2-.06):
   box(name+'窗下墙',(cx,y,z+.27),(w,.12,.4),wall)
   step=w/bays
   for i in range(bays):
    x=cx-w/2+step*(i+.5)
    box(name+'独立玻璃窗',(x,y,z+1.25),(step-.5,.025,1.58),glass)
    box(name+'窗中竖框',(x,y-.08,z+1.25),(.055,.07,1.58),frame)
    box(name+'窗横框',(x,y-.08,z+1.25),(step-.5,.07,.055),frame)
   for i in range(bays+1):
    x=cx-w/2+i*step
    if i in (0,bays):
     x+=.125 if i==0 else -.125;wid=.25
    else:wid=.5
    box(name+'窗间墙',(x,y,z+1.25),(wid,.12,1.58),wall)
  for x in (cx-w/2+.06,cx+w/2-.06):
   # Side elevations have a real centered window instead of a blank wall.
   opening=min(1.2,d*.3);remain=(d-.24-opening)/2
   for sign in (-1,1):
    box(name+'端墙',(x,cy+sign*(opening/2+remain/2),z+1.25),(.12,remain,1.58),wall)
   box(name+'侧窗',(x,cy,z+1.25),(.025,opening,1.58),glass)
   box(name+'侧窗下墙',(x,cy,z+.27),(.12,d-.24,.4),wall)
   box(name+'侧窗横框',(x,cy,z+1.25),(.17,opening,.055),frame)
  for x in (-4,4):
   if abs(x-cx)<w/2-1:box(name+'室内桌',(x,cy,z+.75),(1.2,.6,.12),ivory)
 # gable roof with long ridge on x
 z=.4+n*2.1+.06
 verts=[(cx-w/2-.15,cy-d/2-.2,z),(cx+w/2+.15,cy-d/2-.2,z),(cx+w/2+.15,cy+d/2+.2,z),(cx-w/2-.15,cy+d/2+.2,z)]
 if d>w:verts.extend([(cx,cy-d/2-.2,z+.65),(cx,cy+d/2+.2,z+.65)]);faces=[(0,4,5,3),(4,1,2,5),(0,1,4),(3,5,2),(3,2,1,0)]
 else:verts.extend([(cx-w/2-.15,cy,z+1),(cx+w/2+.15,cy,z+1)]);faces=[(0,1,5,4),(2,3,4,5),(3,0,4),(1,2,5),(3,2,1,0)]
 me=bpy.data.meshes.new('双坡瓦顶');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name+'双坡瓦顶',me);scene.collection.objects.link(o);o.data.materials.append(roof);uv(o)
wing('前翼',0,-5,20,4,3,8)
wing('后翼',0,5,20,4,5,8)
# connecting west block, its own walls and glazing
wing('西连接楼',-9,0,2,6,4,1)
# Courtyard walk, lawn and planted edges.
box('庭院铺地',(1,0,.08),(18,6,.16),floor)
box('庭院草坪',(1,0,.18),(14.6,3.65,.04),grass)
def shrub(name,loc,size,material):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=loc);o=bpy.context.object;o.name=name;o.scale=size;o.data.materials.append(material)
for y in (-2.55,2.55):
 box('庭院花池',(1,y,.26),(16,.7,.35),ivory)
 for j in range(16):
  x=j-6.5
  shrub('庭院灌木',(x,y,.62),(.53,.38,.35),green2 if j%3 else green)
  if j%3==1:shrub('粉色花丛',(x+.2,y-.22,.8),(.28,.22,.2),flower)
box('入口雨棚',(0,-7.35,2.35),(4.5,.75,.18),ivory,.02)
for x in (-2,2):box('门廊柱',(x,-7.65,1.36),(.17,.17,1.8),ivory)
for i in range(3):box('入口台阶',(0,-7.4-i*.28,.32-i*.08),(4,.28,.12),ivory,.01)
world=scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.27,.29,.34,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
bpy.ops.object.light_add(type='AREA',location=(-10,-16,23));light=bpy.context.object;light.data.energy=3200;light.data.shape='DISK';light.data.size=13
bpy.ops.object.camera_add(location=(27,-34,26));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,5.0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=35;scene.camera=cam
scene.render.filepath=os.path.join(out,'B05_预览.png');dg=bpy.context.evaluated_depsgraph_get();tris=0
for obj in scene.objects:
 if obj.type=='MESH':
  ev=obj.evaluated_get(dg);m=ev.to_mesh();m.calc_loop_triangles();tris+=len(m.loop_triangles);ev.to_mesh_clear()
print('TRIANGLES',tris)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'B05_red_roof.blend'))
bpy.ops.render.render(write_still=True)

