import bpy, math, os
from mathutils import Vector
out=r'D:\Research\GameDevelopment\建模\B01_chunhui_有字'
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=12
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


box('基座',(0,0,.2),(18,8,.4),ivory,.04)
# Two dark wings, built from segments around actual slit windows.
for side in (-1,1):
 cx=side*5.6
 # Low glass band at ground level with actual openings.
 for y in (-3.64,3.64):
  box('底层窗下墙',(cx,y,.46),(4.5,.22,.12),ivory)
  box('底层窗上墙',(cx,y,1.04),(4.5,.22,.12),ivory)
  for dx in (-2,0,2):box('底层窗柱',(cx+dx,y,.75),(.18,.22,.46),ivory)
  box('底层窗玻璃',(cx,y,.75),(4.3,.035,.46),glass)
 box('侧翼底层端墙',(side*7.74,0,.75),(.22,7.1,.7),ivory)
 for z in (3.0,5.0,7.0,9.0):box('侧翼内部楼板',(cx,0,z),(4.28,7.1,.14),ivory)
 for y in (-3.64,3.64):
  for k in (-1,0,1):box('深色竖向墙段',(cx+k*1.48,y,5.62),(1.0,.22,8.46),wall)
  for dx in (-.74,.74):
   box('狭长窗玻璃',(cx+dx,y,5.62),(.48,.035,8.46),glass)
   for z in (3,4.5,6,7.5,9):box('狭长窗横框',(cx+dx,y-.12,z),(.43,.08,.06),frame)
  box('窗顶梁',(cx,y,10.05),(4.5,.22,.4),wall)
  box('窗底梁',(cx,y,1.24),(4.5,.22,.3),wall)
 box('侧翼内侧墙',(side*3.46,0,5.25),(.22,7.1,9.7),wall)
 # Side elevation: a broad dark wall with two narrow, physically open windows.
 for lo,hi in [(-2.6,-.825),(-.375,.375),(.825,3.55)]:
  box('山墙窗间墙',(side*8.53,(lo+hi)/2,5.62),(.22,hi-lo,8.46),wall)
 for yc in (-.6,.6):box('山墙窄窗',(side*8.53,yc,5.62),(.035,.45,8.46),glass)
 box('山墙底梁',(side*8.53,.475,1.245),(.22,6.15,.31),wall)
 box('山墙顶梁',(side*8.53,.475,10.0),(.22,6.15,.3),wall)
 box('侧翼屋顶',(side*5.95,0,10.26),(5.4,7.7,.25),ivory,.035)
 box('侧翼顶部檐线',(cx,-3.78,9.85),(4.55,.12,.12),ivory)
 for i in range(3):box('侧翼装饰线',(cx,-3.79,8.9+i*.24),(3,.12,.08),ivory)
# Narrow glazed strips wrap the outer edges of both wings.
for side in (-1,1):
 xx=side*8.22
 for y in (-3.64,3.64):
  box('侧翼外缘玻璃',(xx,y,5.62),(.74,.035,8.46),glass)
  for z in (1.39,3,4.5,6,7.5,9,9.85):box('外缘玻璃横框',(xx,y-.07,z),(.74,.08,.06),frame)
 for y in (-3.6,-3.1,-2.6):box('外侧幕墙竖框',(side*8.66,y,5.62),(.08,.06,8.46),frame)
 box('外侧整面玻璃',(side*8.66,-3.1,5.62),(.035,1.0,8.46),glass)
 box('外侧玻璃下槛',(side*8.66,-3.1,1.245),(.2,1.0,.29),ivory)
 box('外侧玻璃上槛',(side*8.66,-3.1,9.99),(.2,1.0,.28),ivory)
 for z in (1.39,3,4.5,6,7.5,9,9.85):box('外侧幕墙横框',(side*8.66,-3.1,z),(.08,1.0,.06),frame)
# central glazed atrium: floor, glass and frames
box('大厅地面',(0,0,.42),(6.7,7.3,.08),floor)
for y in (-4.05,3.62):
 box('大厅幕墙玻璃',(0,y,5.15),(6.6,.035,9.1),glass)
 for i in range(9):box('幕墙竖框',(-3.3+i*.825,y-.08,5.15),(.06,.07,9.1),frame)
 for z in (.6,2.2,3.8,5.4,7.0,8.6,9.7):box('幕墙横框',(0,y-.08,z),(6.6,.07,.07),frame)
# gabled glass roof, solid underside for a closed surface
verts=[(-3.7,-4.3,9.72),(3.7,-4.3,9.72),(3.7,-1.15,9.72),(-3.7,-1.15,9.72),(0,-4.3,11.55),(0,-1.15,11.55)]
faces=[(0,4,5,3),(4,1,2,5),(0,1,4),(3,5,2),(3,2,1,0)]
me=bpy.data.meshes.new('入口玻璃坡顶');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new('入口玻璃坡顶',me);scene.collection.objects.link(o);o.data.materials.append(glass);uv(o)
# Roof mullions follow both roof slopes and provide a fine glass-grid silhouette.
def beam(name,p1,p2,width,material):
 mid=(Vector(p1)+Vector(p2))/2;delta=Vector(p2)-Vector(p1);o=box(name,mid,(width,width,delta.length),material);o.rotation_euler=delta.to_track_quat('Z','Y').to_euler();return o
for y in (-4.3,-3.5,-2.7,-1.9,-1.15):
 for side in (-1,1):beam('玻璃屋顶横框',(0,y,11.58),(side*3.7,y,9.75),.07,trim)
for xx in (-3.7,-2.47,-1.23,0,1.23,2.47,3.7):
 zz=11.58-abs(xx)*1.83/3.7;beam('玻璃屋顶纵框',(xx,-4.3,zz),(xx,-1.15,zz),.065,trim)
box('中部后方平顶',(0,1.375,9.84),(6.6,5.05,.24),wall,.02)
for z in (2.2,5.4,8.6):
 box('大厅横向梁',(0,-4.18,z),(6.9,.22,.18),ivory,.02)
for x in (-3.15,3.15):box('大厅两侧柱',(x,-4.2,2.0),(.25,.28,3.1),ivory,.02)
box('入口雨棚',(0,-4.45,3.43),(6.4,.8,.25),ivory,.03)
for x in (-2.7,2.7):box('入口门廊柱',(x,-4.74,1.9),(.23,.23,2.9),ivory,.02)
for x in (-1.5,-.75,0,.75,1.5):box('入口玻璃门框',(x,-4.15,1.44),(.06,.08,1.7),frame)
for i in range(4):box('大门台阶',(0,-4.55-i*.32,.33-i*.08),(6,.32,.12),ivory,.015)
# Low planted beds in front of both wings.
for x in (-6.15,6.15):
 box('前庭花池',(x,-4.08,.43),(3.8,.7,.42),ivory,.025)
 box('花池泥土',(x,-4.08,.66),(3.55,.53,.05),dark)
 for j in range(6):
  xx=x-1.42+j*.57
  box('绿篱',(xx,-4.08,.81),(.48,.48,.3),green2 if j%2 else green,.05)
  if j in (1,4):box('粉色花簇',(xx,-4.31,.88),(.22,.13,.18),flower,.02)
# Interior floor plates and lobby fixtures
for z in (3.7,6.9):box('大厅楼层平台',(0,2.1,z),(6.4,2.8,.18),ivory)
for x in (-2,2):
 box('大厅花槽',(x,.8,.7),(.8,.8,.5),ivory,.02)
 box('大厅植物',(x,.8,1.08),(.55,.55,.3),green2,.04)
# Interior reception, seating and balcony rails.
box('大厅接待台',(0,.15,.98),(2.0,.72,1.1),ivory,.035)
box('接待台台面',(0,.15,1.56),(2.12,.82,.1),frame,.015)
for x in (-2.15,2.15):
 box('大厅座椅',(x,1.2,.75),(1.05,.54,.14),ivory,.02)
 for dx in (-.4,.4):box('座椅支架',(x+dx,1.2,.58),(.1,.48,.24),frame)
for z in (3.7,6.9):
 box('室内走廊栏杆',(0,.72,z+.95),(6.3,.07,.07),frame)
 for x in (-3,-1.5,0,1.5,3):box('室内走廊立柱',(x,.72,z+.5),(.07,.07,.9),frame)
# Sign support poles extend to the different sloped roof heights.
for x in (-2.5,0,2.5):
 roofheight=9.96
 box('楼名支撑杆',(x,1,(roofheight+11.1)/2),(.055,.055,11.1-roofheight),frame)
# Red rooftop lettering from a local font, converted to mesh for triangle accounting.
red=mat('楼名字体红色',(.8,.03,.025))
try:
 font=bpy.data.fonts.load(r'C:\Windows\Fonts\msyh.ttc')
 for x,ch in zip((-2.5,0,2.5),'春晖楼'):
  cr=bpy.data.curves.new('楼名字体','FONT');cr.body=ch;cr.font=font;cr.align_x='CENTER';cr.size=1.35;cr.extrude=.025;cr.resolution_u=2
  ob=bpy.data.objects.new('楼名'+ch,cr);scene.collection.objects.link(ob);ob.location=(x,1,11.1);ob.rotation_euler=(math.pi/2,0,0);ob.data.materials.append(red)
  bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.convert(target='MESH');ob.select_set(False)
  import bmesh
  bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
except Exception as e:print('FONT ISSUE',e)
world=scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.27,.29,.34,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7
bpy.ops.object.light_add(type='AREA',location=(-9,-15,20));light=bpy.context.object;light.data.energy=3000;light.data.shape='DISK';light.data.size=12
bpy.ops.object.camera_add(location=(24,-32,20));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,5.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=26;scene.camera=cam
scene.render.filepath=os.path.join(out,'B01_预览.png');dg=bpy.context.evaluated_depsgraph_get();tris=0
for obj in scene.objects:
 if obj.type=='MESH':
  ev=obj.evaluated_get(dg);m=ev.to_mesh();m.calc_loop_triangles();tris+=len(m.loop_triangles);ev.to_mesh_clear()
print('TRIANGLES',tris)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'B01_chunhui.blend'))
bpy.ops.render.render(write_still=True)





