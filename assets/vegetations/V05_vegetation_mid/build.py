import bpy,math,random,os,sys
from mathutils import Vector
kind=sys.argv[sys.argv.index('--')+1];P=os.path.join(r'D:\Research\GameDevelopment\建模',kind);random.seed(31 if kind.startswith('V05') else 47)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def foliage(name,file):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(os.path.join(P,file));n.image.pack();n.interpolation='Closest';b=m.node_tree.nodes.get('Principled BSDF');m.node_tree.links.new(n.outputs['Color'],b.inputs['Base Color']);m.node_tree.links.new(n.outputs['Alpha'],b.inputs['Alpha']);m.node_tree.links.new(n.outputs['Color'],b.inputs['Emission Color']);b.inputs['Emission Strength'].default_value=.12;m.surface_render_method='DITHERED';m.use_transparency_overlap=False;return m
green=foliage('Green foliage','foliage_generated.png');pink=foliage('Pink foliage',('blossom_painted.png' if kind.startswith('V05') else 'blossom_variant.png'))
def mat(name,color):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*color,1);return m
bark=mat('Bark',(.21,.11,.05));grass=mat('Grass',(.21,.38,.04));floor=mat('Studio',(.12,.14,.17))
def branch(a,b,r1,r2):
 a,b=Vector(a),Vector(b);d=b-a;bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=r1,radius2=r2,depth=d.length,location=(a+b)*.5);o=bpy.context.object;o.name='Branch';o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(bark)
def card(pos,size,angle,mat,horizontal=False):
 pos=Vector(pos);w=size*.6;h=size*.40
 if horizontal: verts=[pos+Vector((-w,-h,0)),pos+Vector((w,-h,0)),pos+Vector((w,h,0)),pos+Vector((-w,h,0))]
 else:
  v=Vector((math.cos(angle)*w,math.sin(angle)*w,0));up=Vector((0,0,h));verts=[pos-v-up,pos+v-up,pos+v+up,pos-v+up]
 mesh=bpy.data.meshes.new('Leaf card');mesh.from_pydata(verts,[],[(0,1,2,3)]);mesh.update();o=bpy.data.objects.new('Foliage',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(mat);uv=mesh.uv_layers.new()
 for loop,co in zip(mesh.loops,[(0,0),(1,0),(1,1),(0,1)]):uv.data[loop.index].uv=co
def tree(x,y,h,mat):
 branch((x,y,0),(x,y,h*.72),h*.055,h*.025)
 for i in range(6):
  a=i*math.tau/6;dist=h*random.uniform(.20,.29);end=(x+dist*math.cos(a),y+dist*math.sin(a),h*random.uniform(.70,.90));branch((x,y,h*.42),end,h*.025,h*.006)
  for z in [-.04,.10]:
   p=(end[0],end[1],end[2]+h*z)
   card(p,h*.35,a,mat);card(p,h*.35,a+math.pi/2,mat);card(p,h*.43,0,mat,True)
 for i in range(5):
  a=i*math.tau/5;p=(x+math.cos(a)*h*.12,y+math.sin(a)*h*.12,h*.86);card(p,h*.35,a,mat);card(p,h*.42,0,mat,True)
def bush(x,y,r,mat):
 for i in range(6):
  a=i*math.tau/6;pos=(x+r*.35*math.cos(a),y+r*.35*math.sin(a),r*.50);card(pos,r,a,mat);card(pos,r*1.1,0,mat,True)
if kind.startswith('V05'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=1,depth=.12,location=(0,0,.0));o=bpy.context.object;o.name='Landscape base';o.scale=(4,1.5,1);o.data.materials.append(grass)
 for x,y,h in [(-3,.1,2.6),(-1.3,.5,3.2),(.9,.45,3.4),(2.8,.25,2.6)]:tree(x,y,h,green)
 tree(-1.9,-.6,1.9,pink)
 for i in range(14):bush(-3.3+i*.5,-1.0+random.random()*.2,.36,pink if i in (3,11) else green)
 for i in range(12):bush(-2.9+i*.52,.95+random.random()*.12,.32,green)
else:
 for row in range(2):
  for i in range(9):tree(-4+i*.98+(row*.2),row*.55,2.3+random.random()*.5,green)
asset=bpy.data.collections.new('ASSET '+kind[:3]);bpy.context.scene.collection.children.link(asset)
for o in list(bpy.context.scene.objects):
 for c in list(o.users_collection):c.objects.unlink(o)
 asset.objects.link(o)
stage=bpy.data.collections.new('STUDIO');bpy.context.scene.collection.children.link(stage)
def mov(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 stage.objects.link(o)
bpy.ops.mesh.primitive_plane_add(size=200);o=bpy.context.object;o.data.materials.append(floor);mov(o)
for loc,power in [((-5,-6,9),1200),((5,3,7),700)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=5;mov(o)
bpy.ops.object.camera_add(location=(7,-13,6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.4))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=11;mov(cam)
s=bpy.context.scene;s.camera=cam;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.transparent_max_bounces=64;s.render.resolution_x=1200;s.render.resolution_y=600;s.render.filepath=os.path.join(P,'preview.png');s.world.color=(.25,.25,.25)
tri=0
for o in asset.objects:o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
print('ASSET_TRIS',tri);bpy.ops.wm.save_as_mainfile(filepath=os.path.join(P,kind+'.blend'));bpy.ops.render.render(write_still=True)
