import bpy,math,sys
from pathlib import Path
from mathutils import Vector
index=int(sys.argv[-1]);name='B11_teaching_middle' if index==11 else 'B12_teaching_rear';out=Path(r'D:\Research\GameDevelopment\建模')/name
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(n,c,metal=0,rough=.6):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
stone=mat('Pale concrete',(.72,.70,.69));steel=mat('Window frames',(.18,.27,.31),.45,.4);glass=mat('Opaque blue windows',(.04,.22,.32),.25,.3); shade=mat('Stairwell shadow',(.32,.35,.35)); warm=mat('Entry cladding',(.55,.43,.32))
window_mats=[]
for i in range(4):
 m=glass.copy();m.name='Pixel window %d'%i;n=m.node_tree.nodes;t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(Path(r'D:\Research\GameDevelopment\建模\B11_teaching_middle')/('window_%d.png'%i)));t.image.pack();t.interpolation='Closest';m.node_tree.links.new(t.outputs['Color'],n.get('Principled BSDF').inputs['Base Color']);window_mats.append(m)
def box(n,loc,dim,m,bev=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if bev:
  mod=o.modifiers.new('Edge bevel','BEVEL');mod.width=bev;mod.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
box('Foundation',(0,-.5,.22),(23,9,.44),stone,.04)
box('Main building body',(0,.25,6.86),(18.8,5.7,12.8),stone,.025)
# front and back facades share opaque windows with real structural frames
for y in (-2.62,3.12):
 sign=-1 if y<0 else 1
 for row in range(5):
  z=3.2+row*2.15
  for col in range(6):
   x=-7.5+col*3
   box('Glazing',(x,y,z),(2.44,.035,1.42),window_mats[(row+col*3)%4])
   if y<0:
    for dx in (-1.22,1.22):box('Window vertical',(x+dx,y+sign*.026,z),(.045,.045,1.46),steel)
   
   if y<0:box('Window crossbar',(x,y+sign*.03,z),(2.48,.05,.045),steel)
 for col in range(6):
  x=-7.5+col*3
  box('Ground entrance recess',(x,y,1.28),(2.4,.04,1.7),warm)
  box('Ground door glazing',(x,y+sign*.028,1.28),(1.5,.035,1.45),glass)

 for z in [2.18,4.34,6.49,8.64,10.79,12.94]:box('Horizontal floor ledge',(0,y+sign*.10,z),(19,.20,.16),stone,0)
 for x in [-9,-6,-3,0,3,6,9]:box('Facade pilaster',(x,y+sign*.12,6.8),(.22,.24,11.9),stone,0)
for x in (-10,10):
 box('Tower back',(x,2.7,7),(1.6,.35,13.2),stone,.015)
 for dx in (-.73,.73):
  for yy in (-2.65,2.65):box('Tower column',(x+dx,yy,7),(.16,.16,13.2),stone,.008)
 box('Tower crown',(x,0,13.72),(2.05,6,1.0),stone,.02)
 for floor in range(6):
  z=.48+floor*2.15
  box('Stair landing',(x,-2,z),(1.3,1,.15),stone,0)
  box('Stair landing',(x,2,z),(1.3,1,.15),stone,0)
  if floor<5:
   # One closed, extruded stepped mesh per flight.
   steps=12;profile=[(-2,0)]
   for t in range(steps):
    profile.extend([(-2+4*t/steps,2.15*(t+1)/steps),(-2+4*(t+1)/steps,2.15*(t+1)/steps)])
   profile.append((2,0))
   if floor%2:profile=[(-yy,zz) for yy,zz in profile];profile.reverse()
   N=len(profile);verts=[(x+xx,yy,z+zz) for xx in (-.6,.6) for yy,zz in profile]
   faces=[tuple(reversed(range(N))),tuple(range(N,2*N))]+[(i,(i+1)%N,(i+1)%N+N,i+N) for i in range(N)]
   mesh=bpy.data.meshes.new('Stepped flight');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Stepped flight',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(stone)
   # Outer stair guard follows the flight; uprights terminate on its underside.
   side=1 if x>0 else -1;xx=x+side*.64;slope=2.15/4*(1 if floor%2==0 else -1)
   guard=box('Stair handrail',(xx,0,z+1.075+.72),(.055,math.sqrt(4**2+2.15**2),.055),steel);guard.rotation_euler[0]=math.atan(slope)
   for yy in (-1.7,1.7):
    zz=z+1.075+slope*yy;box('Guard upright',(xx,yy,zz+.35),(.045,.045,.70),steel)

  box('Tower front opaque glazing',(x,-2.82,z+1),(1.35,.035,1.8),glass)
  box('Tower pane divider',(x,-2.85,z+1),(.055,.05,1.8),steel)
# The rear building's side wall extends further over the stairwell than B11.
for side in (-1,1):
 depth=.70 if index==11 else 1.30
 box('Stair tower side wall',(side*10.82,2.75-depth/2,7),(.14,depth,13.1),stone,.006)
 for floor in range(5):box('Narrow side window',(side*10.90,2.75-depth/2,2.9+floor*2.15),(.025,.28,1.2),glass)
box('Roof',(0,0,13.46),(19.1,6.4,.22),stone,.02)
# Low roof coping and three planted beds on the front apron.
for yy in (-2.85,2.85):box('Roof coping',(0,yy,13.66),(18.9,.12,.18),stone,.008)
for xx in (-9.39,9.39):box('Roof coping',(xx,0,13.66),(.12,5.58,.18),stone,.008)
leaf=mat('Pixel shrub green',(.19,.39,.08));leaf2=mat('Pixel shrub light',(.34,.49,.10))
for xx in (-7,0,7):
 box('Planter',(xx,-4.6,.53),(4.3,.65,.18),stone,.01)
 for j in range(5):
  bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.23,location=(xx-1.70+j*.85,-4.6,.83));shrub=bpy.context.object;shrub.name='Low shrub';shrub.data.materials.append(leaf if j%2 else leaf2)
for step in range(3):box('Entrance steps',(0,-3.35-step*.3,.31-step*.1),(22,.3,.12),stone,.008)
scene=bpy.context.scene;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.08,.16,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
for loc,power in [((0,-22,22),8000),((15,8,18),7000)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=15;o.rotation_euler=(Vector((0,0,7))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(30,-45,25));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,7))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=33;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.render.resolution_x=1300;scene.render.resolution_y=850;scene.render.resolution_percentage=100;scene.render.filepath=str(out/(name+'_preview.png'))
tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in scene.objects if o.type=='MESH')
bpy.ops.wm.save_as_mainfile(filepath=str(out/(name+'.blend')));bpy.ops.render.render(write_still=True)
(out/'检查说明.txt').write_text('%s 教学楼\n三角面数：%d\n按三视图估算建筑宽 23 m；含主体、外墙网格、两端楼梯结构与屋顶。\n状态：初稿，两栋基于共用模板，侧墙宽度有所区分，仍需按三视图进一步分别调整。窗为不透明；楼梯已做踏步，增加了简化外侧栏杆；窗采用内嵌的低分辨率简化像素纹理，增加了简化花坛，缺其余材质贴图、法线及内部精细结构，连接处与 360 度还需检查。\n'%(name,tris),encoding='utf-8');print('TRIS',tris)
