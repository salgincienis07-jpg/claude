import struct, sys
def fix(p, only_area=False, dry=False):
    d=bytearray(open(p,'rb').read())
    assert d[:4]==b'IDST'
    nt,ti=struct.unpack_from('<ii',d,180)
    if nt==0: return []
    nsr,nsf,si,nbp,bpi=struct.unpack_from('<iiiii',d,192)
    ratio={}
    for i in range(nt):
        o=ti+i*80
        fl,w,h,idx=struct.unpack_from('<iiii',d,o+64)
        area_bad=(w*h)&3
        if only_area and not area_bad: continue
        if not area_bad and w%4==0 and h%4==0: continue
        nw=max(4,w-w%4) if w>=4 else w; nh=max(4,h-h%4) if h>=4 else h
        if (nw*nh)&3 or nw>w or nh>h: print('SKIP',p,w,h); continue
        if (nw,nh)==(w,h): continue
        ratio[i]=(w,h,nw,nh)
        if dry: continue
        px=bytes(d[idx:idx+w*h]); pal=bytes(d[idx+w*h:idx+w*h+768])
        out=bytearray(nw*nh)
        for y in range(nh):
            sy=min(h-1,int((y+0.5)*h/nh))
            row=sy*w
            for x in range(nw):
                out[y*nw+x]=px[row+min(w-1,int((x+0.5)*w/nw))]
        d[idx:idx+nw*nh]=out; d[idx+nw*nh:idx+nw*nh+768]=pal
        # zero the slack
        d[idx+nw*nh+768:idx+w*h+768]=bytes(w*h-nw*nh)
        struct.pack_into('<ii',d,o+68,nw,nh)
    if not ratio or dry: return ratio
    skins=[struct.unpack_from('<h',d,si+2*k)[0] for k in range(nsr*nsf)]
    for b in range(nbp):
        bo=bpi+b*76; nm,base,mi=struct.unpack_from('<iii',d,bo+64)
        for m in range(nm):
            mo=mi+m*112
            nmesh,meshi=struct.unpack_from('<ii',d,mo+72)
            for e in range(nmesh):
                eo=meshi+e*20
                ntri,tri,sref=struct.unpack_from('<iii',d,eo)
                texs={skins[f*nsr+sref] for f in range(nsf)}
                rs={ratio[t] for t in texs if t in ratio}
                if not rs: continue
                if len(rs)>1 or len(texs)>len([t for t in texs if t in ratio]): print('WARN mixed',p,sref)
                w,h,nw,nh=next(iter(rs))
                q=tri
                while True:
                    c=struct.unpack_from('<h',d,q)[0]; q+=2
                    if c==0: break
                    for v in range(abs(c)):
                        s,t=struct.unpack_from('<hh',d,q+4)
                        struct.pack_into('<hh',d,q+4,round(s*nw/w),round(t*nh/h))
                        q+=8
    open(p,'wb').write(d)
    return ratio
if __name__=='__main__':
    only=sys.argv[1]=='area'
    for p in sys.argv[2:]:
        r=fix(p,only)
        if r: print(p,r)
