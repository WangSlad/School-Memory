import bpy, math, os
from mathutils import Vector
P = dict(bay=8.0, height=3.6, corridor=2.4, depth=7.2, column=0.38, door_w=1.0, door_h=2.35, window_w=1.5, window_h=1.35, railing_h=1.1)
OUT = r'D:/Research/GameDevelopment/school_3d/assets/buildings/teaching_floor'
# Create an isolated scene; do not alter the startup scene.
scene = bpy.data.scenes.new('TeachingFloor_OneStorey')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene['parameters_m'] = str(P)
def mat(name, color, rough=.8, alpha=1):
 m=bpy.data.materials.new(name); m.diffuse_color=(*color,alpha); m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*color,alpha); bs.inputs['Roughness'].default_value=rough; bs.inputs['Alpha'].default_value=alpha
 if alpha<1: m.surface_render_method='DITHERED'
 return m
white=mat('Warm white concrete',(.83,.84,.80)); wall=mat('Soft ivory wall',(.88,.88,.83)); tile=mat('Pale ceramic tile',(.79,.81,.78),.5); grout=mat('Tile joints',(.61,.64,.61)); dark=mat('Deep green frames',(.045,.16,.12),.48); glass=mat('Transparent blue green glass',(.48,.72,.70),.18,.25); steel=mat('Railing metal',(.20,.26,.25),.35); door=mat('Painted green door',(.10,.24,.19)); stairmat=mat('Stair concrete',(.68,.71,.68)); shade=mat('Window glazing',(.22,.34,.32),.35)
def box(name, loc, size, material):
 x,y,z=loc; a,b,c=[s/2 for s in size]
 verts=[(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in [(-1,-1,-1),(-1,-1,1),(-1,1,-1),(-1,1,1),(1,-1,-1),(1,-1,1),(1,1,-1),(1,1,1)]]
 faces=[(0,4,6,2),(1,3,7,5),(0,1,5,4),(2,6,7,3),(0,2,3,1),(4,5,7,6)]
 mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.materials.append(material); mesh.update(); obj=bpy.data.objects.new(name,mesh); scene.collection.objects.link(obj); return obj
# 12 bays: balcony, office, eight classrooms, stairs, toilets, office (13 bays).
bay=P['bay']; H=P['height']; C=P['corridor']; D=P['depth']; n=13; length=n*bay
box('Floor slab', (length/2,(D-C)/2,-.12),(length,D+C,.24),white)
box('Corridor tile', (length/2,-C/2,.006),(length,C,.012),tile)
# Subtle tile joints on the walkable corridor.
for i in range(int(length/.6)+1): box('Tile joint X %03d'%i,(i*.6,-C/2,.013),(.012,C,.003),grout)
for i in range(1,4): box('Tile joint Y %d'%i,(length/2,-i*.6,.014),(length,.012,.003),grout)
box('Upper slab', (length/2,(D-C)/2,H-.10),(length,D+C,.20),white)
box('Corridor beam', (length/2,-C+.19,H-.28),(length,.38,.56),white)
for i in range(n+1): box('Frame column %02d'%i,(i*bay,-C+.19,H/2),(P['column'],P['column'],H),white)
# Glass railing between the columns, with thin metal rails and divisions.
for i in range(n):
 x=i*bay
 box('Glass balustrade %02d'%i,(x+bay/2,-C+.10,P['railing_h']/2),(bay-.42,.025,P['railing_h']-.06),glass)
 box('Handrail %02d'%i,(x+bay/2,-C+.10,P['railing_h']),(bay-.3,.055,.055),steel)
 for j in range(1,5): box('Balustrade post %02d %d'%(i,j),(x+j*bay/5,-C+.10,P['railing_h']/2),(.045,.055,P['railing_h']),steel)
# End balcony is open; other bays have a repeated door/window/door facade.
def facade(i, kind):
 x=i*bay
 # openings: dimensions, centre positions, sill, height
 if kind=='classroom': openings=[(.95,P['door_w'],0,P['door_h']),(3.0,P['window_w'],1.0,P['window_h']),(5.0,P['window_w'],1.0,P['window_h']),(7.05,P['door_w'],0,P['door_h'])]
 elif kind=='stairs': openings=[(4.0,2.2,0,2.65)]
 elif kind=='toilet': openings=[(1.3,1.0,0,2.3),(4.1,1.25,1.35,1.0),(6.2,1.25,1.35,1.0)]
 else: openings=[(1.1,1.0,0,2.35),(3.4,1.5,1.0,1.35),(5.5,1.5,1.0,1.35)]
 last=0
 for k,(cx,w,sill,h) in enumerate(openings):
  left=cx-w/2; right=cx+w/2
  if left>last: box('Facade %02d pier %d'%(i,k),(x+(last+left)/2,.10,H/2),(left-last,.20,H),wall)
  if sill: box('Sill %02d %d'%(i,k),(x+cx,.10,sill/2),(w,.20,sill),wall)
  top=sill+h
  if top<H: box('Lintel %02d %d'%(i,k),(x+cx,.10,(top+H)/2),(w,.20,H-top),wall)
  if kind=='stairs': last=right; continue
  # windows and closed doors are flush with wall; no interiors are furnished.
  box(('Door' if sill==0 else 'Window')+' %02d %d'%(i,k),(x+cx,-.015,sill+h/2),(w,.035,h),door if sill==0 else shade)
  for dx in [-w/2,w/2]: box('Frame upright %02d %d'%(i,k),(x+cx+dx,-.06,sill+h/2),(.07,.08,h+.08),dark)
  for zz in [sill,sill+h]: box('Frame horizontal %02d %d'%(i,k),(x+cx,-.06,zz),(w+.07,.08,.07),dark)
  if sill>0: box('Window mullion %02d %d'%(i,k),(x+cx,-.07,sill+h/2),(.045,.08,h),dark)
  else: box('Door handle %02d %d'%(i,k),(x+cx+w*.32,-.10,1.02),(.035,.06,.16),steel)
  last=right
 if last<bay: box('Facade %02d end'%i,(x+(last+bay)/2,.10,H/2),(bay-last,.20,H),wall)
for i in range(1,n): facade(i,'classroom' if 2<=i<=9 else 'stairs' if i==10 else 'toilet' if i==11 else 'office')
# External shell, no classroom interior furnishings.
box('Rear wall',(length/2,D-.1,H/2),(length,.2,H),wall)
box('Left end wall',(.10,D/2,H/2),(.2,D,H),wall)
box('Right end wall',(length-.10,(D-C)/2,H/2),(.2,D+C,H),wall)
# Stair flight on the stair bay, 18 rises over a full floor, visually explicit.
for s in range(18):
 rise=(s+1)*H/18; box('Stair tread %02d'%s,(10*bay+4.0, .4+s*.30,rise/2),(1.5,.30,rise),stairmat)
box('Stair landing',(10*bay+4,6.3,H-.10),(1.5,1.2,.20),stairmat)
# Save only the isolated scene's objects to the glTF export.
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/teaching_floor.blend')
bpy.ops.export_scene.gltf(filepath=OUT+'/teaching_floor.glb',export_format='GLB',use_selection=True,use_active_scene=True)
result={'objects':len(scene.objects),'length':length,'params':P}



