#!/usr/bin/env python3
"""Freeze asymmetric generating SD experiments using existing frozen oracle."""
import hashlib,json,math
from pathlib import Path
import numpy as np
from scipy.optimize import minimize
import oracle as o
p=Path(__file__).resolve().parent
cases={'none':((),False),'site':((0,),False),'observer':((1,),False),'both':((0,1),False),'mixed':((0,1),True)}
records=[]; fits=[]; data={}; maxg=maxh=0.
for site,obs in ((.03,.6),(.6,.03)):
    name=f'{site}_{obs}'; y=.8+.45*o.XVAL+site*o.SITE_EFFECT[o.SITE]+obs*o.OBS_EFFECT[o.OBS]+np.exp(-.35+.21*o.XVAL)*o.RESIDUAL; data[name]=y.tolist()
    for case,(which,fixed) in cases.items():
        for t in o.POINTS:
            f=lambda v:o.objective(v,y,which,fixed,derivatives=False)
            v,g,h=o.objective(t,y,which,fixed); gn=o.fdgrad(f,t,1e-5); hn=o.fdhess(f,t,2e-4)
            maxg=max(maxg,float(np.max(np.abs(g-gn)))); maxh=max(maxh,float(np.max(np.abs(h-hn)/np.maximum(1,np.abs(h)))))
            records.append({'dataset':name,'case':case,'theta':t.tolist(),'objective':v,'gradient':g.tolist(),'hessian':h.tolist()})
        if which:
            fit=minimize(lambda q:o.objective(q,y,which,fixed)[:2],o.POINTS[0],jac=True,method='L-BFGS-B',bounds=[(None,None)]*4+[(-18.,5.)]*2,options={'maxiter':5000,'ftol':1e-14,'gtol':1e-9,'maxls':50})
            v,g,h=o.objective(fit.x,y,which,fixed)
            fits.append({'dataset':name,'case':case,'theta':fit.x.tolist(),'objective':v,'score_inf':float(np.max(np.abs(g))),'success':bool(fit.success),'message':str(fit.message),'penalized_floor_contact':bool(any(fit.x[4+i]<=-17.99 for i in which)),'hessian_min_eigenvalue':float(np.linalg.eigvalsh(h)[0])})
assert maxg<=1e-6 and maxh<=1e-5
out={'schema':'two-ri-asymmetric-oracle-v1','generator':'0.8+0.45*x+site_sd*site_draw+observer_sd*observer_draw+exp(-0.35+0.21*x)*residual_draw','source_oracle_sha256':hashlib.sha256((p/'oracle.py').read_bytes()).hexdigest(),'source_frozen_sha256':hashlib.sha256((p/'frozen.json').read_bytes()).hexdigest(),'datasets':data,'generating_sd':{'0.03_0.6':[.03,.6],'0.6_0.03':[.6,.03]},'points':records,'fits':fits,'finite_difference_steps':{'gradient':1e-5,'hessian':2e-4},'max_gradient_error':maxg,'max_hessian_scaled_error':maxh}
(p/'asymmetric-frozen.json').write_text(json.dumps(out,indent=2,allow_nan=False)+'\n')
print('ASYMMETRIC_FREEZE',len(records),len(fits),maxg,maxh,hashlib.sha256((p/'asymmetric-frozen.json').read_bytes()).hexdigest())
