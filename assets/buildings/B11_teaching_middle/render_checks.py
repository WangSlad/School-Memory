import bpy,sys
from mathutils import Vector
from pathlib import Path
out=Path(bpy.data.filepath).parent;scene=bpy.context.scene;cam=scene.camera;scene.cycles.samples=8;scene.render.resolution_x=900;scene.render.resolution_y=650
for name,loc,target,scale in [('front',(0,-50,7),(0,0,7),26),('back',(0,50,7),(0,0,7),26),('side',(50,0,7),(0,0,7),22),('top',(0,0,50),(0,0,0),26)]:
 cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale;scene.render.filepath=str(out/('check_'+name+'.png'));bpy.ops.render.render(write_still=True)

