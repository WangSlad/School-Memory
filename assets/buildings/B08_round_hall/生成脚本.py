import bpy, math, os
from mathutils import Vector
out=r'D:\Research\GameDevelopment\建模\B08_round_hall'
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


N=24
# Circular base and mezzanine; isolated glazing leaves the interior visible.
def disk(name,radius,depth,z,material):
 bpy.ops.mesh.primitive_cylinder_add(vertices=N,radius=radius,depth=depth,location=(0,0,z));o=bpy.context.object;o.name=name;o.data.materials.append(material);uv(o)
 bevel=o.modifiers.new('倒角','BEVEL');bevel.width=.035;bevel.segments=1;o.modifiers.new('加权法线','WEIGHTED_NORMAL');return o

disk('圆形基座',8.3,.35,.175,ivory);disk('大厅地面',7.8,.1,.4,floor)
disk('中层环梁',8.18,.26,3.1,ivory);disk('上部檐口',8.1,.22,6.03,ivory)
# Translucent glass panels between columns in two levels
for flooridx in range(2):
 bottom=.46 if flooridx==0 else 3.25; top=2.97 if flooridx==0 else 5.92
 for i in range(N):
  a=2*math.pi*i/N; b=2*math.pi*(i+1)/N
  v=[(7.9*math.cos(a),7.9*math.sin(a),bottom),(7.9*math.cos(b),7.9*math.sin(b),bottom),(7.9*math.cos(b),7.9*math.sin(b),top),(7.9*math.cos(a),7.9*math.sin(a),top)]
  me=bpy.data.meshes.new('玻璃');me.from_pydata(v,[],[(0,1,2,3)]);me.update();o=bpy.data.objects.new('弧形窗扇',me);scene.collection.objects.link(o);o.data.materials.append(glass);uv(o);o.modifiers.new('玻璃厚度','SOLIDIFY').thickness=.025
  col=box('环形立柱',(7.94*math.cos(a),7.94*math.sin(a),(bottom+top)/2),(.19,.19,top-bottom),ivory)
# Ground-level entrance portico and stairs
for x in (-1.8,1.8):box('入口柱',(x,-8.06,1.64),(.3,.3,2.6),ivory,.025)
box('门楣',(0,-8.06,2.94),(4,.3,.18),ivory,.025)
for i in range(4):box('入口台阶',(0,-8.2-i*.3,.32-i*.08),(4.5,.3,.11),ivory,.01)
# Interior furnishing and planters
for x in (-4,-2,0,2,4):
 box('大厅长凳',(x,1,.8),(1.5,.65,.15),ivory,.025)
 for dx in (-.55,.55):box('长凳腿',(x+dx,1,.59),(.12,.55,.3),frame)
# Low-rise spherical dome with concentric rings
verts=[];rings=6
for j in range(rings):
 theta=(math.pi/2)*j/rings;rad=7.9*math.cos(theta);z=6.16+2.5*math.sin(theta)
 for i in range(N):
  a=2*math.pi*i/N;verts.append((rad*math.cos(a),rad*math.sin(a),z))
verts.append((0,0,8.66));faces=[]
for j in range(rings-1):
 for i in range(N):faces.append((j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i))
for i in range(N):faces.append(((rings-1)*N+i,(rings-1)*N+(i+1)%N,rings*N))
faces.append(tuple(reversed(tuple(range(N)))))
me=bpy.data.meshes.new('穹顶');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new('穹顶',me);scene.collection.objects.link(o);o.data.materials.append(roof);uv(o)
# Radial standing seams raised slightly above the dome surface.
ribbon_v=[];ribbon_f=[]
for i in range(N):
 a=2*math.pi*i/N
 for j in range(rings+1):
  theta=(math.pi/2)*j/rings;rad=7.9*math.cos(theta);z=6.18+2.5*math.sin(theta)
  for side in (-1,1):ribbon_v.append((rad*math.cos(a)+side*.025*math.sin(a),rad*math.sin(a)-side*.025*math.cos(a),z))
 for j in range(rings):
  k=i*(rings+1)*2+j*2;ribbon_f.append((k,k+1,k+3,k+2))
me=bpy.data.meshes.new('穹顶放射筋');me.from_pydata(ribbon_v,[],ribbon_f);me.update();o=bpy.data.objects.new('穹顶放射筋',me);scene.collection.objects.link(o);o.data.materials.append(trim);o.modifiers.new('立边厚度','SOLIDIFY').thickness=.012
disk('穹顶顶部装饰',.5,.12,8.7,ivory)
# Double-leaf entrance mullions.
for x in (-1.05,0,1.05):box('玻璃门竖框',(x,-7.94,1.5),(.07,.12,2.05),frame)
box('玻璃门横框',(0,-7.94,2.52),(2.15,.12,.07),frame)
world=scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.27,.29,.34,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
bpy.ops.object.light_add(type='AREA',location=(-10,-15,20));light=bpy.context.object;light.data.energy=2500;light.data.shape='DISK';light.data.size=12
bpy.ops.object.camera_add(location=(19,-25,17));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,3.5))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=23;scene.camera=cam
scene.render.filepath=os.path.join(out,'B08_预览.png');dg=bpy.context.evaluated_depsgraph_get();tris=0
for obj in scene.objects:
 if obj.type=='MESH':
  ev=obj.evaluated_get(dg);m=ev.to_mesh();m.calc_loop_triangles();tris+=len(m.loop_triangles);ev.to_mesh_clear()
print('TRIANGLES',tris)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'B08_round_hall.blend'))
bpy.ops.render.render(write_still=True)



