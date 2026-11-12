import bpy,math,os
from mathutils import Vector
P=r'D:\Research\GameDevelopment\建模\P09_basketball_hoop';os.makedirs(P,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*color,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=.48;return m
green=mat('Green painted steel',(.08,.38,.13));light=mat('Pale green',(.3,.6,.2));white=mat('White painted frame',(.82,.9,.84));blue=mat('Blue backboard',(.1,.36,.49));red=mat('Orange red rim',(.8,.12,.035));net=mat('Basket net',(.85,.85,.76));ground=mat('Backdrop',(.1,.12,.16));blue.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.28;blue.surface_render_method='DITHERED'
def box(name,loc,size,m,b=.012):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if b:
  mod=o.modifiers.new('Beveled edges','BEVEL');mod.width=b;mod.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def beam(name,a,b,width,m):
 mid=(Vector(a)+Vector(b))/2;d=Vector(b)-Vector(a);o=box(name,mid,(width,width,d.length),m,min(.01,width*.12));o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return o
box('Weighted foot',(0,.75,.13),(.8,.8,.26),green,.045)
box('Central post',(0,.75,1.57),(.19,.19,2.75),green,.02)
box('Horizontal backboard support',(0,.32,2.96),(.16,1.0,.16),green,.02)
beam('Angled support',(0,.75,2.6),(0,-.10,3.16),.10,green)
for x in [-.5,.5]:beam('Backboard brace',(0,.75,2.92),(x,-.08,3.25),.07,green)
# translucent backboard with frame
box('Backboard',(0,-.12,3.54),(1.78,.06,.97),blue,.009)
for x in [-.9,.9]:box('Vertical board frame',(x,-.12,3.54),(.065,.09,.98),white,.01)
for z in [4.06]:box('Horizontal board frame',(0,-.12,z),(1.86,.09,.065),white,.01)
box('Lower green board edge',(0,-.12,3.00),(1.86,.15,.11),green,.012)
# bolts and joint collars
for z in [.42,2.72]:
 box('Post connection collar',(0,.75,z),(.23,.23,.12),green,.008)
 for x in [-.065,.065]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.018,depth=.015,location=(x,.625,z),rotation=(math.pi/2,0,0));bpy.context.object.name='Steel fastening';bpy.context.object.data.materials.append(white)
for x in [-.30,.30]:
 for y in [.48,1.02]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.023,depth=.022,location=(x,y,.27));bpy.context.object.name='Base bolt';bpy.context.object.data.materials.append(white)
# painted target square stands slightly off the front surface
for x in [-.31,.31]:box('Target vertical',(x,-.158,3.43),(.026,.01,.374),white,.002)
for z in [3.23,3.63]:box('Target horizontal',(0,-.158,z),(.646,.01,.026),white,.002)
box('Rim mount',(0,-.24,3.12),(.22,.19,.1),red,.012)
bpy.ops.mesh.primitive_torus_add(major_segments=20,minor_segments=6,location=(0,-.46,3.14),major_radius=.225,minor_radius=.018);bpy.context.object.name='Basket rim';bpy.context.object.data.materials.append(red)
# diamond net as slender double-sided ribbons
verts=[];faces=[]
for j in range(4):
 for i in range(16):
  for sign in [-1,1]:
   a=2*math.pi*i/16+j*math.pi/16;b=a+sign*math.pi/16
   r1=.22-.022*j;r2=.22-.022*(j+1);z1=3.12-.10*j;z2=3.12-.10*(j+1)
   p=Vector((r1*math.cos(a),-.46+r1*math.sin(a),z1));q=Vector((r2*math.cos(b),-.46+r2*math.sin(b),z2));side=Vector((math.cos(a),math.sin(a),0))*.004
   k=len(verts);verts.extend([p-side,p+side,q+side,q-side]);faces.append((k,k+1,k+2,k+3))
mesh=bpy.data.meshes.new('Woven net mesh');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Woven net',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(net)
asset=bpy.data.collections.new('ASSET P09');bpy.context.scene.collection.children.link(asset)
for o in list(bpy.context.scene.objects):
 for c in list(o.users_collection):c.objects.unlink(o)
 asset.objects.link(o)
stage=bpy.data.collections.new('STUDIO');bpy.context.scene.collection.children.link(stage)
def mov(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 stage.objects.link(o)
o=box('Floor',(0,0,-.06),(200,200,.1),ground,0);mov(o)
for loc,power in [((-4,-5,7),850),((4,4,6),500)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=5;mov(o)
bpy.ops.object.camera_add(location=(5,-7,4.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=5.2;mov(cam)
s=bpy.context.scene;s.camera=cam;s.render.engine='CYCLES';s.cycles.samples=32;s.render.resolution_x=700;s.render.resolution_y=900;s.render.resolution_percentage=100;s.render.filepath=os.path.join(P,'preview.png');s.world.color=(.2,.2,.2)
tri=0
for o in asset.objects:
 if o.type=='MESH':o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
print('ASSET_TRIS',tri)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(P,'P09_basketball_hoop.blend'));bpy.ops.render.render(write_still=True)
