from PIL import Image,ImageDraw
from pathlib import Path
import random, math
random.seed(84);N=512;im=Image.new('RGBA',(N,N),(0,0,0,0));d=ImageDraw.Draw(im)
main=[(35,340),(150,310),(270,280),(390,230),(485,190)];d.line(main,fill=(101,63,38,255),width=7)
for i in range(20):
 t=random.uniform(.09,.92);x=35+450*t;y=340-150*t+random.uniform(-10,10);ex=x+random.uniform(-45,45);ey=y+random.choice([-1,1])*random.uniform(35,95)
 d.line([(x,y),(ex,ey)],fill=(107,65,38,255),width=3)
 for j in range(9):
  cx=ex+random.uniform(-42,42);cy=ey+random.uniform(-36,36)
  if not 25<cx<487 or not 25<cy<487:continue
  radius=random.uniform(11,17);petal=random.choice([(255,160,190,255),(246,112,160,255),(255,194,207,255),(240,132,177,255),(253,150,176,255)])
  for k in range(5):
   a=2*math.pi*k/5;px=cx+math.cos(a)*radius*.7;py=cy+math.sin(a)*radius*.7;d.ellipse((px-radius*.5,py-radius*.5,px+radius*.5,py+radius*.5),fill=petal)
  d.ellipse((cx-2,cy-2,cx+2,cy+2),fill=(245,218,96,255))
  if j==0:
   lx=cx+random.choice([-1,1])*random.uniform(12,23);ly=cy+random.uniform(5,15);d.polygon([(cx,cy),(lx-5,ly-5),(lx+9,ly-9),(lx+4,ly+3)],fill=random.choice([(119,166,36,255),(83,140,28,255),(160,190,45,255)]))
im.save(r'D:\Research\GameDevelopment\建模\V02_tree_blossom\blossom_painted.png')
