#!/usr/bin/env python3
import hashlib,json
from pathlib import Path
import numpy as np
import oracle as o
p=Path(__file__).resolve().parent
m=json.loads((p/'asymmetric-manifest.json').read_text())
for name,sha in m['sha256'].items(): assert hashlib.sha256((p/name).read_bytes()).hexdigest()==sha,name
x=json.loads((p/'asymmetric-frozen.json').read_text())
assert x['source_oracle_sha256']==hashlib.sha256((p/'oracle.py').read_bytes()).hexdigest()
assert x['source_frozen_sha256']==hashlib.sha256((p/'frozen.json').read_bytes()).hexdigest()
cases={'none':((),False),'site':((0,),False),'observer':((1,),False),'both':((0,1),False),'mixed':((0,1),True)}
mg=mh=0.
for row in x['points']:
    which,fixed=cases[row['case']]; y=np.array(x['datasets'][row['dataset']]); t=np.array(row['theta']); f=lambda v:o.objective(v,y,which,fixed,derivatives=False)
    v,g,h=o.objective(t,y,which,fixed); assert abs(v-row['objective'])/max(1,abs(v))<=1e-8
    assert np.max(np.abs(g-np.array(row['gradient'])))<1e-11 and np.max(np.abs(h-np.array(row['hessian'])))<1e-11
    mg=max(mg,float(np.max(np.abs(g-o.fdgrad(f,t,1e-5))))); mh=max(mh,float(np.max(np.abs(h-o.fdhess(f,t,2e-4))/np.maximum(1,np.abs(h)))))
assert len(x['points'])==60 and mg<=1e-6 and mh<=1e-5
for fit in x['fits']:
    which,fixed=cases[fit['case']]; v,g,h=o.objective(np.array(fit['theta']),np.array(x['datasets'][fit['dataset']]),which,fixed)
    assert abs(v-fit['objective'])<1e-9 and max(abs(g))<1e-5 and not fit['penalized_floor_contact']
for key in x['datasets']:
    y=np.array(x['datasets'][key]); t=o.POINTS[0]; correct=o.objective(t,y,(0,),derivatives=False)
    for kind in ('wrong_target','swap_shape_rate','omit_normalizer','omit','double','per_group','jacobian'):
        assert abs(correct-o.objective(t,y,(0,),mutation=kind,derivatives=False))>1e-5
print('ASYMMETRIC_VALIDATED',len(x['points']),'points',len(x['fits']),'fits',f'grad={mg:.3g}',f'hess={mh:.3g}')
