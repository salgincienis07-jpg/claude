import struct,sys
for p in sys.argv[1:]:
    d=open(p,'rb').read()
    nt,ti=struct.unpack_from('<ii',d,180); nsr,nsf,si,nbp,bpi=struct.unpack_from('<iiiii',d,192)
    if not nt: continue
    tex=[struct.unpack_from('<ii',d,ti+i*80+68) for i in range(nt)]
    mx={}
    for b in range(nbp):
        nm,base,mi=struct.unpack_from('<iii',d,bpi+b*76+64)
        for m in range(nm):
            nmesh,meshi=struct.unpack_from('<ii',d,mi+m*112+72)
            for e in range(nmesh):
                ntri,q,sref=struct.unpack_from('<iii',d,meshi+e*20)
                t=struct.unpack_from('<h',d,si+2*sref)[0]
                while True:
                    c=struct.unpack_from('<h',d,q)[0];q+=2
                    if not c:break
                    for v in range(abs(c)):
                        s,tt=struct.unpack_from('<hh',d,q+4);q+=8
                        a=mx.setdefault(t,[0,0]);a[0]=max(a[0],s);a[1]=max(a[1],tt)
    for t,(s,tt) in mx.items():
        w,h=tex[t]
        if s>w+1 or tt>h+1: print(p,t,'uv',s,tt,'tex',w,h)
print('ok')
