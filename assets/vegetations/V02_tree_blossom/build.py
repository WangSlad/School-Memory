import bpy,math,random,os
from mathutils import Vector
P=r'D:\Research\GameDevelopment\建模\V02_tree_blossom';random.seed(22)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,col):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True;m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*col,1);return m
bark=mat('Warm bark',(.25,.12,.05));root=bark;floor=mat('Studio',(.12,.14,.17))
n=bark.node_tree.nodes;links=bark.node_tree.links;tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=6;tex.inputs['Detail'].default_value=2;coord=n.new('ShaderNodeTexCoord');vec=n.new('ShaderNodeVectorMath');vec.operation='MULTIPLY';vec.inputs[1].default_value=(4,4,.45);ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=(.08,.035,.014,1);ramp.color_ramp.elements[1].color=(.42,.22,.08,1);links.new(coord.outputs['Generated'],vec.inputs[0]);links.new(vec.outputs['Vector'],tex.inputs['Vector']);links.new(tex.outputs['Fac'],ramp.inputs['Fac']);links.new(ramp.outputs['Color'],n.get('Principled BSDF').inputs['Base Color'])
leaves=[]
for i in range(4):
 m=bpy.data.materials.new('Reference foliage '+str(i));m.use_nodes=True;n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(os.path.join(P,'blossom_painted.png'));n.image.pack();n.interpolation='Closest';b=m.node_tree.nodes.get('Principled BSDF');m.node_tree.links.new(n.outputs['Color'],b.inputs['Base Color']);m.node_tree.links.new(n.outputs['Alpha'],b.inputs['Alpha']);m.surface_render_method='DITHERED';m.use_transparency_overlap=False;leaves.append(m)
def branch(name,a,b,r1,r2,m=bark):
 a,b=Vector(a),Vector(b);d=b-a;bpy.ops.mesh.primitive_cone_add(vertices=9,radius1=r1,radius2=r2,depth=d.length,location=(a+b)/2);o=bpy.context.object;o.name=name;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(m)
# One closed trunk mesh, with buttress roots formed by its flared lower rings.
levels=[(0,.27),(.10,.24),(.38,.20),(1.3,.165),(2.5,.145),(3.4,.115),(3.9,.085)];verts=[];N=12
for j,(z,r) in enumerate(levels):
 for i in range(N):
  a=math.tau*i/N;flare=(1.0+(.62 if i%3==0 else 0)) if j==0 else (1.0+(.24 if i%3==0 else 0) if j==1 else 1.0);cx=.025*math.sin(z*1.3);cy=.022*math.sin(z*.9);verts.append((cx+r*flare*math.cos(a),cy+r*flare*math.sin(a),z))
faces=[(i,(i+1)%N) for i in range(N)];faces=[(a,b,b+N,a+N) for a,b in faces]
for j in range(1,len(levels)-1):
 for i in range(N):
  a=j*N+i;b=j*N+(i+1)%N;faces.append((a,b,b+N,a+N))
faces.append(tuple(reversed(range(N))));faces.append(tuple((len(levels)-1)*N+i for i in range(N)))
mesh=bpy.data.meshes.new('Flared trunk');mesh.from_pydata(verts,[],faces);mesh.update();ob=bpy.data.objects.new('Trunk and roots',mesh);bpy.context.collection.objects.link(ob);mesh.materials.append(bark)
clusters=[]
for i in range(12):
 a=i*2*math.pi/12+random.uniform(-.12,.12);z=random.uniform(2.7,3.7);dist=random.uniform(1.3,2.05);end=Vector((dist*math.cos(a),dist*math.sin(a),random.uniform(4.1,5.0)));start=Vector((0,0,z));branch('Primary branch',start,end,.075,.025)
 clusters.append(end)
 for k in range(3):
  angle=a+random.uniform(-.45,.45);rad=dist+random.uniform(-.3,.45);q=Vector((rad*math.cos(angle),rad*math.sin(angle),end.z+random.uniform(-.05,.8)));branch('Twig',end*.6+start*.4,q,.022,.006);clusters.append(q)
for i in range(12):
 a=i*math.tau/12;clusters.append(Vector((random.uniform(.3,1.15)*math.cos(a),random.uniform(.3,1.15)*math.sin(a),random.uniform(4.6,5.6))))
# 3 intersecting foliage cards per cluster create volume around all viewpoints
for k,pos in enumerate(clusters):
 size=random.uniform(.8,1.15)
 for j in range(5):
  ang=(random.uniform(0,math.tau) if j>=3 else j*math.pi/3+random.uniform(-.15,.15));v=(Vector((math.cos(ang)*size*.78,math.sin(ang)*size*.78,0)) if j>=3 else Vector((math.cos(ang)*size*.55,math.sin(ang)*size*.55,0)));h=(Vector((-math.sin(ang)*size*.58,math.cos(ang)*size*.58,random.uniform(-.12,.12))) if j>=3 else Vector((0,0,size*.4)));offset=(Vector((0,0,random.uniform(-.12,.12))) if j>=3 else Vector((0,0,0)));verts=[pos+offset-v-h,pos+offset+v-h,pos+offset+v+h,pos+offset-v+h];mesh=bpy.data.meshes.new('foliage');mesh.from_pydata(verts,[],[(0,1,2,3)]);mesh.update();ob=bpy.data.objects.new('Foliage cluster',mesh);bpy.context.collection.objects.link(ob);ob.data.materials.append(leaves[k%4]);uv=mesh.uv_layers.new()
  for loop,co in zip(mesh.loops,[(0,0),(1,0),(1,1),(0,1)]):uv.data[loop.index].uv=co
bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.72,depth=.08,location=(0,0,.015));base=bpy.context.object;base.name='Grass base';base.data.materials.append(mat('Grass',(.19,.38,.04)))
asset=bpy.data.collections.new('ASSET V02');bpy.context.scene.collection.children.link(asset)
for o in list(bpy.context.scene.objects):
 for c in list(o.users_collection):c.objects.unlink(o)
 asset.objects.link(o)
stage=bpy.data.collections.new('STUDIO');bpy.context.scene.collection.children.link(stage)
def mov(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 stage.objects.link(o)
bpy.ops.mesh.primitive_plane_add(size=200);o=bpy.context.object;o.data.materials.append(floor);mov(o)
for loc,power in [((-5,-6,9),1100),((6,2,8),700)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=5;mov(o)
bpy.ops.object.camera_add(location=(7,-10,6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,2.8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=7.8;mov(cam)
s=bpy.context.scene;s.camera=cam;s.render.engine='CYCLES';s.cycles.samples=32;s.cycles.transparent_max_bounces=64;s.render.resolution_x=800;s.render.resolution_y=900;s.render.resolution_percentage=100;s.render.filepath=os.path.join(P,'preview.png');s.world.color=(.25,.25,.25)
tri=0
for o in asset.objects:
 if o.type=='MESH':o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
print('ASSET_TRIS',tri);bpy.ops.wm.save_as_mainfile(filepath=os.path.join(P,'V02_tree_blossom.blend'));bpy.ops.render.render(write_still=True)


