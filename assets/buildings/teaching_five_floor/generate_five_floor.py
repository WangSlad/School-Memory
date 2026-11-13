import bpy, math
from mathutils import Vector
from collections import defaultdict
SOURCE = r'D:/Research/GameDevelopment/school_3d/assets/buildings/teaching_floor/teaching_floor.blend'
OUT = r'D:/Research/GameDevelopment/school_3d/assets/buildings/teaching_five_floor'
P = dict(floors=5, bay=10.4, height=4.32, corridor=4.8, depth=7.2, stair_bay=10, rise=.24, run=.4, flight_width=2.10)
# Load the confirmed module from disk, then create a separate output scene.
with bpy.data.libraries.load(SOURCE) as (available, imported):
 imported.scenes=[s for s in available.scenes if s.startswith('TeachingFloor_OneStorey')][-1:]
source=imported.scenes[0]
scene=bpy.data.scenes.new('FiveFloorTeachingBuilding')
bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'
scene['parameters_m']=str(P)
H=P['height']; bay=P['bay']; C=P['corridor']; D=P['depth']; L=14*bay
SX=bay/8.0; SY=C/2.4; stair_x=11.5*bay
STAIRS=(1.5*bay,stair_x)
slabmat=bpy.data.materials.new('Blue grey floor slab')
slabmat.diffuse_color=(.36,.48,.57,1)
slabmat.use_nodes=True
slab_bs=slabmat.node_tree.nodes.get('Principled BSDF')
slab_bs.inputs['Base Color'].default_value=(.36,.48,.57,1)
slab_bs.inputs['Roughness'].default_value=.8
for obj in source.objects:
 if obj.type=='MESH' and obj.name.startswith('Corridor beam'):
  obj.data.materials[0]=slabmat
# Merge repeatable source geometry by material and collision purpose. The same
# meshes are linked on each floor to retain instancing in Blender and glTF.
solid_prefix=('Facade','Sill','Lintel','Door ','Window ','Frame column','Glass balustrade','Rear wall','Left end wall','Right end wall')
skip_prefix=('Floor slab','Upper slab','Stair tread','Stair landing','Corridor beam')
groups=defaultdict(list)
for o in source.objects:
 if o.type!='MESH' or o.name.startswith(skip_prefix): continue
 material=o.data.materials[0] if o.data.materials else None
 key=('solid' if o.name.startswith(solid_prefix) else 'detail',material.name if material else '')
 groups[key].append(o)
def source_point(obj, v):
 p=obj.matrix_world @ v.co
 # Stretch the repeated bay and corridor without changing classroom depth.
 source_x=p.x
 p.x *= SX
 # Insert a full bay after the balcony, shifting the existing block right.
 if source_x >= 8.0 or obj.name.startswith('Frame column 01'): p.x += bay
 if p.y < 0: p.y *= SY
 # Keep doors and railings at their original height; extend the wall above them.
 if p.z > 2.35: p.z=2.35+(p.z-2.35)*(H-2.35)/(3.6-2.35)
 # End the fascia at the underside of the slab to avoid overlapping faces.
 if obj.name.startswith('Frame column'): p.z=min(p.z,H-.24)
 # Broaden the stair entrance independently of the classroom openings.
 if obj.name.startswith(('Facade 10 pier 0','Facade 10 end','Lintel 10 0')):
  old_left=82.9*SX+bay; old_right=85.1*SX+bay
  new_left=stair_x-2.45; new_right=stair_x+2.45
  if obj.name.startswith('Facade 10 pier 0'):
   p.x=11*bay+(p.x-11*bay)*(new_left-11*bay)/(old_left-11*bay)
  elif obj.name.startswith('Facade 10 end'):
   p.x=new_right+(p.x-old_right)*(12*bay-new_right)/(12*bay-old_right)
  else: p.x=new_left+(p.x-old_left)*(new_right-new_left)/(old_right-old_left)
 return tuple(p)
def merged(name, objects, material, flip=True, transform_source=False):
 verts=[]; faces=[]
 for obj in objects:
  off=len(verts)
  verts.extend([source_point(obj,v) if transform_source else tuple(obj.matrix_world @ v.co) for v in obj.data.vertices])
  faces.extend([tuple(off+i for i in (reversed(poly.vertices) if flip else poly.vertices)) for poly in obj.data.polygons])
 mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
 if material: mesh.materials.append(material)
 return mesh
for (kind,matname), objs in groups.items():
 mesh=merged(kind+'_'+matname,objs,bpy.data.materials.get(matname),transform_source=True)
 for f in range(P['floors']):
  o=bpy.data.objects.new('F%02d_%s_%s'%(f+1,kind,matname),mesh); scene.collection.objects.link(o); o.location.z=f*H
white=next(o.data.materials[0] for o in source.objects if o.name.startswith('Floor slab'))
steel=next(o.data.materials[0] for o in source.objects if o.name.startswith('Handrail'))
stairmat=next(o.data.materials[0] for o in source.objects if o.name.startswith('Stair tread'))
# Cheerful Japanese-school palette, retaining the source material structure and glass alpha.
palette = {
 'Warm white concrete': (.88,.90,.87), 'Soft ivory wall': (.91,.90,.82),
 'Pale ceramic tile': (.78,.82,.73), 'Tile joints': (.62,.69,.61),
 'Deep green frames': (.10,.32,.36), 'Transparent blue green glass': (.51,.80,.78),
 'Railing metal': (.11,.36,.43), 'Painted green door': (.36,.62,.63),
 'Stair concrete': (.73,.80,.76), 'Window glazing': (.22,.43,.48),
}
for obj in source.objects:
 for material in obj.data.materials if obj.type == 'MESH' else ():
  if not material: continue
  for prefix, rgb in palette.items():
   if material.name.startswith(prefix):
    alpha=material.diffuse_color[3]
    material.diffuse_color=(*rgb,alpha)
    bs=material.node_tree.nodes.get('Principled BSDF') if material.use_nodes else None
    if bs: bs.inputs['Base Color'].default_value=(*rgb,alpha)
    break
def box(name, loc, size, material):
 x,y,z=loc; a,b,c=[v/2 for v in size]
 vs=[(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in [(-1,-1,-1),(-1,-1,1),(-1,1,-1),(-1,1,1),(1,-1,-1),(1,-1,1),(1,1,-1),(1,1,1)]]
 fs=[(0,4,6,2),(1,3,7,5),(0,1,5,4),(2,6,7,3),(0,2,3,1),(4,5,7,6)]
 m=bpy.data.meshes.new(name); m.from_pydata(vs,[],[tuple(reversed(face)) for face in fs]); m.materials.append(material); m.update(); o=bpy.data.objects.new(name,m); scene.collection.objects.link(o); return o
def rail_between(name,a,b):
 a,b=Vector(a),Vector(b); midpoint=(a+b)/2; obj=box(name,(0,0,0),(.055,.055,(b-a).length),steel); obj.location=midpoint; obj.rotation_mode='QUATERNION'; obj.rotation_quaternion=(b-a).to_track_quat('Z','Y')
def solid_flight(name, x, start, direction, base, material):
 # Closed stepped prism: a continuous underside and connected tread/riser faces.
 import bmesh
 run=P['run']; rise=P['rise']; width=P['flight_width']; steps=9
 profile=[(start,base+rise)]
 for i in range(steps):
  y=start+direction*run*(i+1)
  height=base+rise*(i+1)
  profile.append((y,height))
  if i<steps-1: profile.append((y,height+rise))
 profile.extend([(start+direction*run*steps,base+rise*steps-.28),(start,base-.04)])
 n=len(profile)
 verts=[(x+dx,y,z) for dx in (-width/2,width/2) for y,z in profile]
 faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
 for i in range(n):
  j=(i+1)%n
  faces.append((i,j,n+j,n+i))
 mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.materials.append(material); mesh.update()
 bm=bmesh.new(); bm.from_mesh(mesh); bmesh.ops.recalc_face_normals(bm,faces=bm.faces); bm.to_mesh(mesh); bm.free(); mesh.update()
 obj=bpy.data.objects.new(name,mesh); scene.collection.objects.link(obj)
 return obj
# Upper floors have two shafts; side walls enclose each staircase.
for f in range(6):
 z=f*H-.12
 if f==0 or f==5:
  box('solid_slab_%d'%f,(L/2,(D-C)/2,z),(L,D+C,.24),slabmat)
 else:
  # Keep the corridor continuous and cut only the two stair wells behind it.
  box('solid_slab_%d_corridor'%f,(L/2,-C/2,z),(L,C,.24),slabmat)
  limits=[0,STAIRS[0]-2.4,STAIRS[0]+2.4,STAIRS[1]-2.4,STAIRS[1]+2.4,L]
  for i in (0,2,4):
   a,b=limits[i],limits[i+1]
   box('solid_slab_%d_segment_%d'%(f,i),((a+b)/2,D/2,z),(b-a,D,.24),slabmat)
# The inserted bay repeats the same frame, floor finish and facade opening.
for f in range(5):
 z=f*H; x=STAIRS[0]
 box('solid_new_column_%d'%f,(bay,-C+.38,z+(H-.24)/2),(.494,.76,H-.24),white)
 # Keep the beam sections between columns, ending at the slab underside.
 for k in range(14):
  box('detail_beam_%d_%d'%(f,k),((k+.5)*bay,-C+.38,z+H-.54),(bay-.494,.76,.60),slabmat)
 for side in (-1,1):
  a,b=(bay,x-2.45) if side==-1 else (x+2.45,2*bay)
  box('solid_left_stair_facade_%d_%d'%(f,side),((a+b)/2,.1,z+H/2),(b-a,.2,H),white)
 box('solid_left_stair_lintel_%d'%f,(x,.1,z+(H+2.65)/2),(4.9,.2,H-2.65),white)
 glass=next(o.data.materials[0] for o in source.objects if o.name.startswith('Glass balustrade'))
 box('solid_new_glass_%d'%f,(x,-C+.2,z+.55),(bay-.55,.05,1.04),glass)
 box('detail_new_railing_%d'%f,(x,-C+.2,z+1.1),(bay-.4,.07,.055),steel)
 for j in range(1,5): box('detail_new_railing_post_%d'%f,(bay+j*bay/5,-C+.2,z+.55),(.055,.07,1.1),steel)
 # Close the exposed left end of the balcony with matching glass.
 box('solid_balcony_end_glass_%d'%f,(.1,-C/2,z+.55),(.05,C-.35,1.04),glass)
 box('detail_balcony_end_top_%d'%f,(.1,-C/2,z+1.1),(.07,C-.25,.055),steel)
 for j in range(1,4): box('detail_balcony_end_post_%d'%f,(.1,-j*C/4,z+.55),(.07,.055,1.1),steel)
 # Solid walls directly flank the flights, with a solid rear wall as before.
 for stair in STAIRS:
  for dx in (-2.37,2.37):
   box('solid_stair_side_%d'%f,(stair+dx,D/2,z+H/2),(.14,D,H),white)
# Two 9-step flights and a continuous central turn on each staircase.
for stair_x in STAIRS:
 for f in range(4):
  z=f*H
  solid_flight('detail_solid_flight_A_%d'%f,stair_x-1.2,.8,1,z,stairmat)
  solid_flight('detail_solid_flight_B_%d'%f,stair_x+1.2,4.4,-1,z+H/2,stairmat)
  box('solid_midlanding_%d'%f,(stair_x,5.8,z+H/2-.10),(4.6,2.8,.20),stairmat)
  box('solid_toplanding_%d'%f,(stair_x,.4,z+H-.10),(4.6,.8,.20),stairmat)
  # Central U-shaped handrail follows the ascending flights and turns at the landing.
  for x,flight in ((stair_x-.08,'A'),(stair_x+.08,'B')):
   if flight=='A':
    rail_between('detail_centre_rail_A_%d'%f,(x,.8,z+1.05),(x,4.4,z+H/2+1.05))
   else:
    rail_between('detail_centre_rail_B_%d'%f,(x,4.4,z+H/2+1.05),(x,.8,z+H+1.05))
   for i in range(5):
    zz=z+P['rise']+.52+i*2*P['rise'] if flight=='A' else z+H-P['rise']+.52-i*2*P['rise']
    box('detail_centre_post_%d'%f,(x,1+i*.8,zz),(.045,.045,1.04),steel)
  rail_between('detail_centre_turn_%d'%f,(stair_x-.08,4.4,z+H/2+1.05),(stair_x+.08,4.4,z+H/2+1.05))
bpy.context.view_layer.update()
stair_groups=defaultdict(list)
for obj in list(scene.objects):
 if obj.name.startswith('detail_'):
  stair_groups[obj.data.materials[0].name].append(obj)
for material_name, objects in stair_groups.items():
 mesh=merged('StairDetail_'+material_name, objects, bpy.data.materials.get(material_name), False)
 obj=bpy.data.objects.new('detail_stairs_'+material_name,mesh); scene.collection.objects.link(obj)
 for old in objects: bpy.data.objects.remove(old, do_unlink=True)
source_name=source.name
for other in list(bpy.data.scenes):
 if other != scene: bpy.data.scenes.remove(other)
for o in scene.objects: o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/teaching_five_floor.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/teaching_five_floor.glb',export_format='GLB',use_selection=True,use_active_scene=True)
result={'source_scene':source_name,'objects':len(scene.objects),'floors':5,'groups':len(groups)}







