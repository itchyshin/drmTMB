#!/usr/bin/env python3
"""Independent profiled dense marginal fit; records every deterministic attempt."""
import argparse, json, os, pathlib, sys, time
os.environ.setdefault('OPENBLAS_NUM_THREADS','1')
import numpy as np
import scipy
from scipy.linalg import cho_factor, cho_solve
from scipy.optimize import minimize
from verify import evaluate, conditional_beta, LIMITS
P=pathlib.Path(__file__).parent

def fit_one(f):
 W=np.asarray(f['W']); X=np.asarray(f['X']); y=np.asarray(f['y']); groups=np.asarray(f['group']); K=(groups[:,None]==groups[None,:]); ng=W.shape[1]
 def prof(q, boundary=False):
  gamma=q[:ng]; variance=0. if boundary else q[-1]
  if not np.isfinite(variance) or variance < 0 or not np.all(np.isfinite(gamma)):
   raise ValueError('nonfinite or negative variance/profile coordinate')
  point={'gamma':gamma.tolist(),'tau':float(np.sqrt(variance)),'beta':f['point']['beta']}
  t=dict(f,point=point); point['beta']=conditional_beta(t).tolist(); value,gradient=evaluate(f,point)
  V=variance*K+np.diag(np.exp(2*W@gamma)); c=cho_factor(V,lower=True); r=y-X@point['beta']; z=cho_solve(c,r); A=cho_solve(c,np.eye(len(y)))-np.outer(z,z); gv=.5*np.sum(A*K)
  return value, (gradient[len(point['beta']):-1] if boundary else np.r_[gradient[len(point['beta']):-1],gv]),point,float(gv)
 attempts=[]
 for boundary in (True,False):
  for scale in (-0.5,0.,0.5):
   start=np.zeros(ng); start[0]=scale
   if not boundary: start=np.r_[start,0.04 if scale<0 else 0.5 if scale==0 else 1.5]
   def fun(q):
    try:
     v,g,_,_=prof(q,boundary); return v,g
    except (ValueError,OverflowError,np.linalg.LinAlgError,FloatingPointError): return 1e100,np.zeros_like(q)
   opt=minimize(fun,start,method='L-BFGS-B',jac=True,bounds=[(None,None)]*ng+([] if boundary else [(0.,None)]), options={'maxiter':2000,'ftol':1e-13,'gtol':1e-8,'maxls':50})
   try:
    value,gradient,point,gv=prof(opt.x,boundary)
    coefficients=evaluate(f,point)[1][:-1]
    fitted_boundary=point['tau']==0.
    projected=np.r_[coefficients,min(gv,0.) if fitted_boundary else gv]
    finite=bool(np.isfinite(value) and np.isfinite(gv) and np.all(np.isfinite(coefficients)) and np.all(np.isfinite(projected)) and
                all(np.all(np.isfinite(v)) for v in point.values()))
    kkt=float(np.max(np.abs(projected))) if finite else None
    eligible=bool(opt.success and finite and kkt <= LIMITS['gradient'])
    attempts.append(dict(boundary=fitted_boundary,subproblem_boundary=boundary,
                         start=start.tolist(),success=bool(opt.success),eligible=eligible,
                         rejection_reason=None if eligible else ('optimizer_nonconvergence' if not opt.success else 'nonfinite' if not finite else 'projected_kkt'),
                         message=str(opt.message),iterations=int(opt.nit),nll=float(value),
                         point=point,profile_gradient=gradient.tolist(),variance_score=gv,
                         projected_kkt=projected.tolist(),max_abs_projected_kkt=kkt))
   except Exception as e: attempts.append(dict(boundary=None,subproblem_boundary=boundary,start=start.tolist(),success=False,eligible=False,rejection_reason='invalid_point',message=repr(e)))
 eligible=[a for a in attempts if a.get('eligible',False)]; best=min(eligible,key=lambda a:a['nll']) if eligible else None
 return dict(id=f['id'],attempts=attempts,best=best)

def main():
 a=argparse.ArgumentParser();a.add_argument('--preflight',action='store_true');a.add_argument('--output',required=True);args=a.parse_args();start=time.monotonic(); files=sorted((P/'fixtures').glob('ri_*.json')); fixtures=[json.loads(x.read_text()) for x in files]; fixtures=[f for f in fixtures if f['preflight']] if args.preflight else fixtures
 assert len(fixtures)==(4 if args.preflight else 12), 'incomplete fixture set'
 assert {f['id'] for f in fixtures}=={f'ri_{i:02d}' for i in range(1,5 if args.preflight else 13)}, 'unexpected fixture ids'
 result={'oracle':'profiled-variance-v2','python':sys.version,'numpy':np.__version__,'scipy':scipy.__version__,'blas_threads':os.getenv('OPENBLAS_NUM_THREADS'),'kkt_limit':LIMITS['gradient'],'results':[fit_one(f) for f in fixtures]};result['seconds']=time.monotonic()-start;pathlib.Path(args.output).write_text(json.dumps(result,indent=2,allow_nan=False)+'\n');missing=[x['id'] for x in result['results'] if x['best'] is None];print(json.dumps({'cases':len(result['results']),'seconds':result['seconds'],'missing_best':missing,'output':args.output}));
 if missing: sys.exit(1)
 print('FIT_ORACLE_PASS')
if __name__=='__main__': main()
