import bpy,math,random,os
from mathutils import Vector
P=r'D:\Research\GameDevelopment\建模\V04_vegetation_front';os.makedirs(P,exist_ok=True);random.seed(16)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
m=bpy.data.materials.new('Green leaf card');m.use_nodes=True;tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(os.path.join(P,'foliage_generated.png'));tex.image.pack();tex.interpolation='Closest';bs=m.node_tree.nodes.get('Principled BSDF');m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);m.node_tree.links.new(tex.outputs['Alpha'],bs.inputs['Alpha']);m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Emission Color']);bs.inputs['Emission Strength'].default_value=.25;m.surface_render_method='DITHERED';m.use_transparency_overlap=False
# foliage distributed through a rounded bush volume
for ix in range(-3,4):
 for iy in range(-3,4):
  x=ix*.32;y=iy*.32;radius=(x*x+y*y)**.5
  if radius>1.05:continue
  top=.4+.9*max(0,1-(radius/1.2)**2)**.5
  for iz in range(2):
   pos=Vector((x,y,top-(1-iz)*.42+random.uniform(-.07,.07)));size=.9
   for j in range(4):
    angle=j*math.pi/3+random.uniform(-.15,.15);v=Vector((math.cos(angle)*size*.55,math.sin(angle)*size*.55,0));up=Vector((0,0,size*.36));verts=([pos+Vector((-size*.8,-size*.55,0)),pos+Vector((size*.8,-size*.55,0)),pos+Vector((size*.8,size*.55,0)),pos+Vector((-size*.8,size*.55,0))] if j==3 else [pos-v-up,pos+v-up,pos+v+up,pos-v+up])
    mesh=bpy.data.meshes.new('leaf card');mesh.from_pydata(verts,[],[(0,1,2,3)]);mesh.update();ob=bpy.data.objects.new('Leaf sprays',mesh);bpy.context.collection.objects.link(ob);mesh.materials.append(m);uv=mesh.uv_layers.new()
    for l,co in zip(mesh.loops,[(0,0),(1,0),(1,1),(0,1)]):uv.data[l.index].uv=co
asset=bpy.data.collections.new('ASSET V04');bpy.context.scene.collection.children.link(asset)
for o in list(bpy.context.scene.objects):
 for c in list(o.users_collection):c.objects.unlink(o)
 asset.objects.link(o)
stage=bpy.data.collections.new('STUDIO');bpy.context.scene.collection.children.link(stage)
def mov(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 stage.objects.link(o)
bpy.ops.mesh.primitive_plane_add(size=200);o=bpy.context.object;mat=bpy.data.materials.new('Backdrop');mat.use_nodes=True;mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.12,.14,.17,1);o.data.materials.append(mat);mov(o)
for loc,power in [((-5,-6,8),1000),((5,3,7),750)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=5;mov(o)
bpy.ops.object.camera_add(location=(4,-6,3));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.7))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.8;mov(cam)
s=bpy.context.scene;s.camera=cam;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.transparent_max_bounces=64;s.render.resolution_x=800;s.render.resolution_y=700;s.render.filepath=os.path.join(P,'preview.png');s.world.color=(.25,.25,.25)
tri=0
for o in asset.objects:o.data.calc_loop_triangles();tri+=len(o.data.loop_triangles)
print('ASSET_TRIS',tri);bpy.ops.wm.save_as_mainfile(filepath=os.path.join(P,'V04_vegetation_front.blend'));bpy.ops.render.render(write_still=True)
