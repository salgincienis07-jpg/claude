from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
FB='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'; FR='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
W,H=740,500
# back: space-grey anodised aluminium, brushed, emblem + wordmark (mirrored correctly when seen from behind)
rng=np.random.default_rng(3)
base=np.zeros((H,W,3)); y=np.linspace(0,1,H)[:,None]; x=np.linspace(0,1,W)[None,:]
lum=58+14*(1-y)+6*np.sin(x*3.1)
noise=rng.normal(0,1,(H,W)); noise=np.asarray(Image.fromarray(((noise*20)+128).clip(0,255).astype(np.uint8)).filter(ImageFilter.BoxBlur(0)).resize((W,H)))/255.0-0.5
brush=np.asarray(Image.fromarray(((rng.normal(0,1,(H,W))*30)+128).clip(0,255).astype(np.uint8)).filter(ImageFilter.GaussianBlur((12,0.3))))/255.0-0.5
for c,(k) in enumerate((1.0,0.98,1.04)): base[...,c]=(lum*k+brush*14+noise*4)
im=Image.fromarray(base.clip(0,255).astype(np.uint8)); d=ImageDraw.Draw(im)
cx,cy,s=W*0.5,H*0.43,H*0.17
glow=Image.new('L',(W,H),0); ImageDraw.Draw(glow).ellipse([cx-s*1.6,cy-s*1.6,cx+s*1.6,cy+s*1.6],fill=255); glow=glow.filter(ImageFilter.GaussianBlur(30))
im=Image.composite(Image.new('RGB',(W,H),(150,20,40)),im,glow.point(lambda v:int(v*0.35))); d=ImageDraw.Draw(im)
# emblem: rounded square with V (polished, slightly reflective)
r=int(s*0.32)
d.rounded_rectangle([cx-s,cy-s,cx+s,cy+s],r,fill=(26,10,16),outline=(214,206,218),width=4)
V=[(cx-s*0.62,cy-s*0.58),(cx-s*0.3,cy-s*0.58),(cx,cy+s*0.22),(cx+s*0.3,cy-s*0.58),(cx+s*0.62,cy-s*0.58),(cx+s*0.12,cy+s*0.66),(cx-s*0.12,cy+s*0.66)]
d.polygon(V,fill=(236,232,240))
d.polygon([(cx-s*0.12,cy+s*0.66),(cx+s*0.12,cy+s*0.66),(cx,cy+s*0.86)],fill=(225,36,59))
d.ellipse([cx-s*0.82,cy-s*0.82,cx+s*0.82,cy+s*0.82],outline=(225,36,59),width=3)
f=ImageFont.truetype(FB,int(H*0.115)); t='VEXMIRA'; sp=int(H*0.03)
ws=[d.textbbox((0,0),ch,font=f)[2] for ch in t]; tot=sum(ws)+sp*(len(t)-1); xx=(W-tot)/2; yy=H*0.7
for ch,w in zip(t,ws):
    d.text((xx+2,yy+2),ch,font=f,fill=(20,18,24)); d.text((xx,yy),ch,font=f,fill=(232,228,236)); xx+=w+sp
f2=ImageFont.truetype(FR,int(H*0.04)); t2='Designed by smurfsexy'
bb=d.textbbox((0,0),t2,font=f2); d.text(((W-(bb[2]-bb[0]))/2,H*0.86),t2,font=f2,fill=(150,145,155))
# camera bump (top-left when seen from behind)
d.rounded_rectangle([28,24,128,124],26,fill=(34,32,38),outline=(90,88,96),width=3)
for (ex,ey,rr) in ((60,56,20),(98,96,14)):
    d.ellipse([ex-rr,ey-rr,ex+rr,ey+rr],fill=(8,10,18),outline=(120,120,130),width=3)
    d.ellipse([ex-rr*0.45,ey-rr*0.45,ex+rr*0.45,ey+rr*0.45],fill=(30,40,70))
d.ellipse([104,40,114,50],fill=(220,210,170))
im.save('back2.png')
# screen: the UI render with a glass sheen
sc=Image.open('screen_ui.png').convert('RGB').resize((W,H),Image.LANCZOS)
a=np.asarray(sc,np.float64)
sheen=np.clip(1.0-(x*0.8+y*1.2),0,1)**3*28
a=a+sheen[...,None]
Image.fromarray(a.clip(0,255).astype(np.uint8)).save('screen2.png')
print('ok')
