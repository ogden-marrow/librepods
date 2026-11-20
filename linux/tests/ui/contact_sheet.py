import sys,glob,os
from PIL import Image,ImageDraw
out=sys.argv[1]; names=sys.argv[2:]
cell=(330,330); cols=5
ims=[]
for n in names:
    im=Image.open(n).convert("RGB"); lab=os.path.basename(n).replace(".png","")
    im.thumbnail((cell[0]-10,cell[1]-30)); ims.append((im,lab))
rows=(len(ims)+cols-1)//cols
sheet=Image.new("RGB",(cols*cell[0],rows*cell[1]),(60,60,60))
d=ImageDraw.Draw(sheet)
for i,(im,lab) in enumerate(ims):
    x=(i%cols)*cell[0]+5; y=(i//cols)*cell[1]+5
    d.text((x,y),lab,fill=(255,255,0)); sheet.paste(im,(x,y+18))
sheet.save(out)
