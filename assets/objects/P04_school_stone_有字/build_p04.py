import bpy,math,random
from pathlib import Path
from mathutils import Vector
out=Path(r'D:\Research\GameDevelopment\建模\P04_school_stone_有字')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(n,c,rough=.8):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;return m
stone=mat('Warm granite',(.58,.55,.53));base=mat('Granite pedestal',(.42,.44,.46))
n=stone.node_tree.nodes;links=stone.node_tree.links;p=n.get('Principled BSDF');noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=18;noise.inputs['Detail'].default_value=3;ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=(.29,.29,.30,1);ramp.color_ramp.elements[1].color=(.72,.68,.65,1);links.new(noise.outputs['Fac'],ramp.inputs[0]);links.new(ramp.outputs[0],p.inputs['Base Color']);b=n.new('ShaderNodeBump');b.inputs['Strength'].default_value=.2;b.inputs['Distance'].default_value=.03;links.new(noise.outputs['Fac'],b.inputs['Height']);links.new(b.outputs['Normal'],p.inputs['Normal'])
def box(n,loc,dim,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m);mod=o.modifiers.new('Bevel','BEVEL');mod.width=.025;mod.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
box('Lower platform',(0,0,.08),(6.5,1.7,.16),base);box('Upper platform',(0,0,.23),(5.85,1.2,.14),base)
# Profile follows the rounded irregular outline of the engraved campus stone.
profile=[(-2.70,.30),(2.70,.30),(2.72,.70),(2.65,1.12),(2.48,1.55),(2.25,1.78),(1.8,1.93),(1.35,1.88),(.9,1.98),(.45,1.9),(0,1.97),(-.5,1.91),(-1,1.98),(-1.5,1.90),(-2,1.88),(-2.38,1.70),(-2.60,1.35),(-2.70,.90)]
N=len(profile);verts=[(x,y,z) for y in (-.48,.48) for x,z in profile];faces=[tuple(reversed(range(N))),tuple(range(N,2*N))]+[(i,(i+1)%N,(i+1)%N+N,i+N) for i in range(N)]
mesh=bpy.data.meshes.new('Stone mesh');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Carved granite boulder',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(stone);bpy.context.view_layer.objects.active=o;o.select_set(True);mod=o.modifiers.new('Rounded edge','BEVEL');mod.width=.12;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False)
# inscription is a transparent decal slightly in front of the stone
m=bpy.data.materials.new('Red painted inscription');m.use_nodes=True;n=m.node_tree.nodes;links=m.node_tree.links;p=n.get('Principled BSDF');p.inputs['Roughness'].default_value=.9;tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(out/'stone_inscription.png'));tex.image.pack();links.new(tex.outputs['Color'],p.inputs['Base Color']);links.new(tex.outputs['Alpha'],p.inputs['Alpha']);m.surface_render_method='DITHERED'
bpy.ops.mesh.primitive_plane_add(size=2,location=(0,-.485,1.1),rotation=(math.pi/2,0,0));o=bpy.context.object;o.name='Inscription decal';o.scale=(2.4,.47,1);o.data.materials.append(m)
scene=bpy.context.scene;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.08,.16,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.8
for loc,power in [((0,-6,7),1200),((4,3,5),900)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=6;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(6,-12,4.5));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=8;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=1200;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'P04_preview.png')
tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in scene.objects if o.type=='MESH')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'P04_school_stone.blend'));bpy.ops.render.render(write_still=True)
(out/'检查说明.txt').write_text('P04 校名石\n三角面数：%d\n估算宽 6.5 m；石体与台座分件，校名为独立透明贴花并内嵌纹理。\n状态：初稿；石体造型和石材纹理与参考图有较大差异，未做像素风材质及法线贴图。透明贴花为开放平面；应按目标引擎检查透明排序、贴花偏移及 360 度外观。\n'%tris,encoding='utf-8');print('TRIS',tris)
