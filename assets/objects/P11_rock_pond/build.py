import bpy,math,random,os
from mathutils import Vector
P=r'D:\Research\GameDevelopment\建模\P11_rock_pond';os.makedirs(P,exist_ok=True);random.seed(33)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*color,1);return m
rocks=[mat('Rock %d'%i,c) for i,c in enumerate([(.47,.42,.31),(.65,.59,.45),(.72,.65,.51),(.43,.45,.31),(.57,.53,.42)])];green=mat('Moss',(.27,.42,.06));grass=mat('Grass',(.28,.49,.08));leaf=mat('Lily leaves',(.22,.48,.07));pink=mat('Blossom',(.92,.30,.53));water=mat('Pond teal',(.025,.38,.36));white=mat('Waterfall foam',(.58,.9,.81));stage_mat=mat('Studio',(.12,.14,.17))
# mottled stone and cascading water shading
for m in rocks:
 nodes=m.node_tree.nodes;links=m.node_tree.links;col=tuple(nodes.get('Principled BSDF').inputs['Base Color'].default_value);tex=nodes.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=18;tex.inputs['Detail'].default_value=2;r=nodes.new('ShaderNodeValToRGB');r.color_ramp.elements[0].color=tuple(v*.65 for v in col[:3])+(1,);r.color_ramp.elements[1].color=tuple(min(1,v*1.15) for v in col[:3])+(1,);links.new(tex.outputs['Fac'],r.inputs['Fac']);links.new(r.outputs['Color'],nodes.get('Principled BSDF').inputs['Base Color'])
nodes=white.node_tree.nodes;links=white.node_tree.links;tex=nodes.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=35;tex.inputs['Detail'].default_value=2;r=nodes.new('ShaderNodeValToRGB');r.color_ramp.elements[0].color=(.06,.42,.38,1);r.color_ramp.elements[1].color=(.8,.95,.86,1);links.new(tex.outputs['Fac'],r.inputs['Fac']);links.new(r.outputs['Color'],nodes.get('Principled BSDF').inputs['Base Color'])
# color variations for water surface
nodes=water.node_tree.nodes;links=water.node_tree.links;noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=35;noise.inputs['Detail'].default_value=2;ramp=nodes.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=(.008,.16,.15,1);ramp.color_ramp.elements[1].color=(.08,.57,.48,1);links.new(noise.outputs['Fac'],ramp.inputs[0]);links.new(ramp.outputs['Color'],nodes.get('Principled BSDF').inputs['Base Color'])
def rock(loc,scale,material=None):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=(2 if max(scale)>.3 and random.random()<.55 else 1),radius=1,location=loc);o=bpy.context.object;o.name='Irregular rock';o.scale=scale;o.rotation_euler=(random.random(),random.random(),random.random()*math.tau);o.data.materials.append(material or random.choice(rocks));return o
def disk(name,loc,rad,depth,mat,sy=1):
 bpy.ops.mesh.primitive_cylinder_add(vertices=(48 if rad>1 else 8),radius=rad,depth=depth,location=loc);o=bpy.context.object;o.name=name;o.scale.y=sy;o.data.materials.append(mat);return o
def box(name,loc,scale,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);return o
# round base with pond front and rock garden rising behind
base=disk('Grassy island',(0,0,.06),3.1,.12,grass,.84)
disk('Water surface',(0,-.72,.135),2.3,.018,water,.65)
# rocks along water rim
for i in range(42):
 a=math.tau*i/42;x=2.38*math.cos(a);y=-.72+1.58*math.sin(a);r=random.uniform(.12,.20);rock((x,y,.20),(r*1.3,r,r*.9))
# continuous backing mass below the hill
rock((-1.1,1.12,.52),(1.0,.95,.72),rocks[3]);rock((1.1,1.12,.52),(1.0,.95,.72),rocks[3]);rock((0,1.4,.65),(.75,.48,.75),rocks[3]);rock((0,1.52,1.10),(.42,.37,.64),rocks[2]);rock((0,.6,.20),(.45,.45,.26),rocks[3])
# mountain behind pond, layered clustered rocks
for row in range(5):
 y=.35+row*.32;extent=2.3-row*.38
 for j in range(max(4,10-row)):
  x=-extent+2*extent*j/(max(4,10-row)-1)+random.uniform(-.12,.12);z=.22+row*.31+random.uniform(.0,.10)
  if abs(x)<.38 and row<4:continue
  r=random.uniform(.25,.38);rock((x,y,z),(r*.85,r*.65,r*random.uniform(1.2,1.8)))
# continuous cascading water mesh, connecting the upper pool to the pond
path=[(-.22,.16),(-.05,.23),(.10,.48),(.26,.53),(.40,.76),(.57,.81),(.70,1.03),(.87,1.08),(1.02,1.30)]
verts=[]
for i,(y,z) in enumerate(path):
 width=.25+.035*math.sin(i*2.7);verts.extend([(-width,y,z),(width,y,z)])
faces=[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(path)-1)]
mesh=bpy.data.meshes.new('Cascade surface');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Continuous cascade',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(white);mesh.materials.append(water)
for i,poly in enumerate(mesh.polygons):poly.material_index=(1 if i%2==0 else 0)
mod=o.modifiers.new('Water thickness','SOLIDIFY');mod.thickness=.02;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
# moss/flowers on rocky banks
for i in range(55):
 x=random.uniform(-2.15,2.15);y=random.uniform(.25,1.6)
 if abs(x)<.5:continue
 z=.21
 rock((x,y,z),(.1,.11,.08),pink if i%8==0 else green)
# foliage accents around rock edges
for fn,matname in [('foliage_generated.png','Leaf accents'),('blossom_painted.png','Pink flowers')]:
 m=bpy.data.materials.new(matname);m.use_nodes=True;node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=bpy.data.images.load(os.path.join(P,fn));node.image.pack();node.interpolation='Closest';bs=m.node_tree.nodes.get('Principled BSDF');m.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color']);m.node_tree.links.new(node.outputs['Alpha'],bs.inputs['Alpha']);m.surface_render_method='DITHERED';m.use_transparency_overlap=False
 if matname=='Leaf accents':green_card=m
 else:pink_card=m
for i,(x,y,z) in enumerate([(-2,.25,.34),(-1.55,.45,.45),(-1.2,.7,.70),(-.75,1.0,.95),(.75,1,.95),(1.2,.7,.7),(1.55,.45,.45),(2,.25,.34),(-2,1.0,.30),(2,1.0,.30),(-1.5,1.35,.40),(1.5,1.35,.40)]):
 for j in range(2):
  a=j*math.pi/2+.3;v=Vector((math.cos(a)*.36,math.sin(a)*.36,0));h=Vector((0,0,.25));pos=Vector((x,y,z));verts=[pos-v-h,pos+v-h,pos+v+h,pos-v+h];mesh=bpy.data.meshes.new('plant card');mesh.from_pydata(verts,[],[(0,1,2,3)]);mesh.update();o=bpy.data.objects.new('Rock garden plants',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(pink_card if i%4==1 else green_card);uv=mesh.uv_layers.new()
  for loop,co in zip(mesh.loops,[(0,0),(1,0),(1,1),(0,1)]):uv.data[loop.index].uv=co
# lilies distributed on pond surface
for x,y in [(-1.3,-.9),(.9,-.7),(.35,-1.5),(-.4,-1.3),(1.35,-1.2)]:
 for j in range(4):
  a=j*math.tau/4;disk('Lily pad',(x+.1*math.cos(a),y+.08*math.sin(a),.157),.12,.008,leaf,.72)
 rock((x,y,.19),(.06,.06,.05),pink)
asset=bpy.data.collections.new('ASSET P11');bpy.context.scene.collection.children.link(asset)
for o in list(bpy.context.scene.objects):
 for c in list(o.users_collection):c.objects.unlink(o)
 asset.objects.link(o)
stage=bpy.data.collections.new('STUDIO');bpy.context.scene.collection.children.link(stage)
def mov(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 stage.objects.link(o)
bpy.ops.mesh.primitive_plane_add(size=200);o=bpy.context.object;o.data.materials.append(stage_mat);mov(o)
for loc,power in [((-5,-6,9),1000),((5,3,7),700)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=5;mov(o)
bpy.ops.object.camera_add(location=(8,-11,7));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.7))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=8;mov(cam)
s=bpy.context.scene;s.camera=cam;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.transparent_max_bounces=64;s.render.resolution_x=900;s.render.resolution_y=700;s.render.filepath=os.path.join(P,'preview.png');s.world.color=(.25,.25,.25)
tri=0
for o in asset.objects:o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
print('ASSET_TRIS',tri);bpy.ops.wm.save_as_mainfile(filepath=os.path.join(P,'P11_rock_pond.blend'));bpy.ops.render.render(write_still=True)
