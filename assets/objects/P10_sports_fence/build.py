import bpy, math, os
from mathutils import Vector
P=r'D:\Research\GameDevelopment\建模\P10_sports_fence'
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for m in list(bpy.data.materials): bpy.data.materials.remove(m)
def material(name,color,tex=None,alpha=False):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.7
 if tex:
  n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(os.path.join(P,tex));n.image.pack();n.interpolation='Closest'
  m.node_tree.links.new(n.outputs['Color'],bs.inputs['Base Color'])
  if alpha:
   m.node_tree.links.new(n.outputs['Alpha'],bs.inputs['Alpha']);m.surface_render_method='DITHERED';m.use_transparency_overlap=False
 return m
green=material('painted green metal',(0.20,.46,.05),'green.png'); concrete=material('pixel mottled concrete',(.58,.55,.49),'concrete.png'); wire=material('diamond mesh',(.3,.5,.1),'fence_mesh.png',True);dark=material('collar dark green',(.12,.31,.03)); hi=material('post highlights',(.48,.75,.13))
def cube(name,loc,scale,mat,bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 if bevel:
  mod=o.modifiers.new('small rounded edges','BEVEL');mod.width=bevel;mod.segments=1;mod.affect='EDGES';bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def cyl(name,loc,rad,depth,mat,vertices=12,rotation=None):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=rad,depth=depth,location=loc,rotation=rotation or (0,0,0));o=bpy.context.object;o.name=name;o.data.materials.append(mat);return o
cube('Concrete footing',(0,0,.10),(2.8,.34,.2),concrete,.025)
for x in [-1.22,1.22]:
 cube('Post square base',(x,0,.225),(.27,.27,.05),green,.01)
 cyl('Foot collar',(x,0,.29),.105,.10,dark)
 cyl('Tall round post',(x,0,1.19),.065,1.8,green)
 cyl('Top collar',(x,0,2.03),.095,.095,dark)
 cyl('Top collar trim',(x,0,2.085),.105,.025,hi)
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=1,location=(x,0,2.15));o=bpy.context.object;o.name='Rounded finial';o.scale=(.09,.09,.075);o.data.materials.append(green)
 for s in [-1,1]:
  cyl('Mount bolt',(x+s*.085,-.145,.255),.016,.015,hi,8,(math.pi/2,0,0))
for z in [.37,1.97]:
 cyl('Horizontal rail',(0,0,z),.044,2.35,green,12,(0,math.pi/2,0))
# flat alpha mesh between rails, physically separate from the frame
verts=[(-1.16,.002,.41),(1.16,.002,.41),(1.16,.002,1.93),(-1.16,.002,1.93)]
me=bpy.data.meshes.new('diamond wire panel');me.from_pydata(verts,[],[(0,1,2,3)]);me.update();ob=bpy.data.objects.new('Diamond wire screen',me);bpy.context.collection.objects.link(ob);ob.data.materials.append(wire)
uv=me.uv_layers.new(name='UVMap')
for loop,co in zip(me.loops,[(0,0),(1,0),(1,1),(0,1)]):uv.data[loop.index].uv=co
# stage excluded from asset collection
asset=bpy.data.collections.new('ASSET P10');bpy.context.scene.collection.children.link(asset)
for o in list(bpy.context.scene.objects):
 for c in list(o.users_collection): c.objects.unlink(o)
 asset.objects.link(o)
stage=bpy.data.collections.new('STUDIO');bpy.context.scene.collection.children.link(stage)
def stage_move(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 stage.objects.link(o)
mat=material('studio floor',(.13,.15,.18));o=cube('Studio floor',(0,0,-.055),(200,200,.1),mat,0);stage_move(o)
world=bpy.context.scene.world;world.color=(.18,.18,.18)
bpy.ops.object.light_add(type='AREA',location=(-3,-4,7));o=bpy.context.object;o.data.energy=600;o.data.shape='DISK';o.data.size=5;stage_move(o)
bpy.ops.object.light_add(type='AREA',location=(4,2,4));o=bpy.context.object;o.data.energy=350;o.data.size=4;stage_move(o)
bpy.ops.object.camera_add(location=(4,-6,3));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=4.2;stage_move(cam)
s=bpy.context.scene;s.camera=cam;s.render.engine='CYCLES';s.cycles.samples=32;s.render.resolution_x=900;s.render.resolution_y=700;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.render.filepath=os.path.join(P,'preview.png')
s.view_settings.view_transform='AgX'
tri=0
for ob in asset.objects:
 if ob.type=='MESH':
  ob.data.calc_loop_triangles();tri+=len(ob.data.loop_triangles)
print('ASSET_TRIS',tri)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(P,'P10_sports_fence.blend'))
bpy.ops.render.render(write_still=True)
