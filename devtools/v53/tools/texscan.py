import struct, sys, os
def bad(w,h): return (w*h)&3 or w<4 or h<4 or w%4 or h%4
out=[]
def mdl(p):
    d=open(p,'rb').read()
    if d[:4]!=b'IDST': return
    n,ti=struct.unpack_from('<ii',d,180)
    for i in range(n):
        o=ti+i*80
        name=d[o:o+64].split(b'\0')[0].decode('latin1')
        fl,w,h,idx=struct.unpack_from('<iiii',d,o+64)
        if bad(w,h): out.append((p,name,w,h))
def spr(p):
    d=open(p,'rb').read()
    if d[:4]!=b'IDSP': return
    nf=struct.unpack_from('<i',d,28)[0]
    pc=struct.unpack_from('<h',d,40)[0]; o=42+pc*3
    def single(o,tag):
        x,y,w,h=struct.unpack_from('<iiii',d,o)
        if bad(w,h): out.append((p,tag,w,h))
        return o+16+w*h
    for f in range(nf):
        t=struct.unpack_from('<i',d,o)[0]; o+=4
        if t==0: o=single(o,'frame%d'%f)
        else:
            g=struct.unpack_from('<i',d,o)[0]; o+=4+4*g
            for k in range(g): o=single(o,'frame%d.%d'%(f,k))
def bsp(p):
    d=open(p,'rb').read()
    off,ln=struct.unpack_from('<ii',d,4+2*8)
    n=struct.unpack_from('<i',d,off)[0]
    for i in range(n):
        mo=struct.unpack_from('<i',d,off+4+4*i)[0]
        if mo<0: continue
        b=off+mo
        name=d[b:b+16].split(b'\0')[0].decode('latin1')
        w,h=struct.unpack_from('<II',d,b+16)
        if w%16 or h%16: out.append((p,name,w,h))
for root in sys.argv[1:]:
    for dp,_,fs in os.walk(root):
        for f in fs:
            p=os.path.join(dp,f); fl=f.lower()
            try:
                if fl.endswith('.mdl'): mdl(p)
                elif fl.endswith('.spr'): spr(p)
                elif fl.endswith('.bsp'): bsp(p)
            except Exception as e: out.append((p,'ERR '+str(e),0,0))
for r in out: print(*r)
print('bad:',len(out))
