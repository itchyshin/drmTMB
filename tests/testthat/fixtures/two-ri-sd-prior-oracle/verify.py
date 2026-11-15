#!/usr/bin/env python3
"""Verify frozen fixture bytes, stored values and central differences, without regenerating it."""
import hashlib, json, math
from pathlib import Path
import numpy as np
import oracle
p=Path(__file__).resolve().parent
manifest=json.loads((p/'manifest.json').read_text())
for name,digest in manifest['sha256'].items():
    assert hashlib.sha256((p/name).read_bytes()).hexdigest()==digest, f'hash mismatch: {name}'
x=json.loads((p/'frozen.json').read_text())
cases={'none':((),False),'site':((0,),False),'observer':((1,),False),'both':((0,1),False),'mixed':((0,1),True)}
maxg=maxh=maxobj=0.
for row in x['records']:
    t=np.array(row['theta']); y=np.array(x['response'][row['dataset']]); which,fixed=cases[row['case']]
    f=lambda a:oracle.objective(a,y,which,fixed,derivatives=False)
    obj,g,h=oracle.objective(t,y,which,fixed)
    maxobj=max(maxobj,abs(obj-row['objective'])/max(1,abs(row['objective'])))
    maxg=max(maxg,float(np.max(np.abs(g-oracle.fdgrad(f,t,1e-5)))))
    maxh=max(maxh,float(np.max(np.abs(h-oracle.fdhess(f,t,2e-4))/np.maximum(1,np.abs(h)))))
    assert np.max(np.abs(g-np.array(row['gradient'])))<1e-11
    assert np.max(np.abs(h-np.array(row['hessian'])))<1e-11
assert maxobj<=1e-8 and maxg<=1e-6 and maxh<=1e-5
assert len(x['records'])>=5 and len(x['negative_control_objective_differences'])==7
assert all(v>1e-5 for v in x['negative_control_objective_differences'].values())
for fit in x['fits']:
    which,fixed=cases[fit['case']]; t=np.array(fit['theta']); y=np.array(x['response'][fit['dataset']]); v,g,h=oracle.objective(t,y,which,fixed)
    assert abs(v-fit['objective'])<1e-9 and max(abs(g))<1e-5
    assert all(t[4+i]>-17.99 for i in which), 'penalized SD reached floor'
# Gamma density transforms as p_scaled(c*tau)=p(tau)/c when rate is divided by c.
c=4.1
for shape,rate in oracle.PRIORS:
    tau=.8; base=rate*tau-(shape-1)*math.log(tau)-shape*math.log(rate)+math.lgamma(shape)
    changed=(rate/c)*(c*tau)-(shape-1)*math.log(c*tau)-shape*math.log(rate/c)+math.lgamma(shape)
    assert abs((changed-base)-math.log(c))<1e-12
print('ORACLE_VALIDATED',len(x['records']),'points',len(x['fits']),'fits',len(x['negative_control_objective_differences']),'mutations',f'grad={maxg:.3g}',f'hess={maxh:.3g}')
# Recompute the deliberately wrong objectives, rather than trusting frozen deltas.
t=oracle.POINTS[0]; y=oracle.Y['0.03']; correct=oracle.objective(t,y,(0,),derivatives=False)
for mutation,old_delta in x['negative_control_objective_differences'].items():
    delta=abs(oracle.objective(t,y,(0,),mutation=mutation,derivatives=False)-correct)
    assert delta>1e-5 and abs(delta-old_delta)<1e-11, (mutation,delta,old_delta)
# At zero, use an exact covariance calculation; approach it from an interior
# parameter while the other SD remains positive. Test each target independently.
for target in (0,1):
    other=1-target
    diag=np.exp(2*(t[2]+t[3]*oracle.XVAL)); V=np.diag(diag)+np.exp(2*t[4+other])*oracle.K[other]
    resid=y-oracle.X@t[:2]; sign,ld=np.linalg.slogdet(V); assert sign==1
    zero=.5*(len(y)*math.log(2*math.pi)+ld+resid@np.linalg.solve(V,resid))
    near=t.copy(); near[4+target]=-18.
    assert abs(oracle.objective(near,y,derivatives=False)-zero)<1e-12
    less=near.copy(); less[4+target]=-10.
    assert oracle.objective(near,y,(target,),derivatives=False)>oracle.objective(less,y,(target,),derivatives=False)
print('MUTATIONS_AND_INDIVIDUAL_ZERO_VALIDATED')
