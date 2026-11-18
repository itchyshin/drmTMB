#!/usr/bin/env python3
"""Dense marginal Gaussian oracle, plus frozen-fixture and mutation checks."""
import argparse, json, math, os, pathlib, sys
os.environ.setdefault('OPENBLAS_NUM_THREADS','1')
import numpy as np
from scipy.linalg import cho_factor, cho_solve
P=pathlib.Path(__file__).parent
LIMITS={'value':1e-9,'gradient':1e-6,'hessian':1e-5,'fit_objective':1e-7,'identified_coefficient':1e-5}
def err(a,b):
 a=np.asarray(a); b=np.asarray(b); return float(np.max(np.abs(a-b)/(1+np.maximum(np.abs(a),np.abs(b)))))
def evaluate(f, point=None):
 y=np.array(f['y']); X=np.array(f['X']); W=np.array(f['W']); groups=np.array(f['group']); p=point or f['point']; beta=np.array(p['beta']); gamma=np.array(p['gamma']); tau=p['tau']; n=len(y)
 V=tau*tau*(groups[:,None]==groups[None,:])+np.diag(np.exp(2*W@gamma)); c=cho_factor(V,lower=True); r=y-X@beta; z=cho_solve(c,r); inv=cho_solve(c,np.eye(n)); val=.5*(n*np.log(2*np.pi)+2*np.log(np.diag(c[0])).sum()+r@z)
 grad=np.r_[-X.T@z,np.zeros(W.shape[1]),0.]; A=inv-np.outer(z,z); s2=np.exp(2*W@gamma)
 grad[len(beta):len(beta)+len(gamma)]=W.T@(np.diag(A)*s2); grad[-1]=tau*np.sum(A*(groups[:,None]==groups[None,:]))
 for pr in f['priors']:
  j=pr['index']+(0 if pr['block']=='beta' else len(beta)); v=np.r_[beta,gamma][j]
  if pr['kind']=='normal':
   d=(v-pr['mean'])/pr['sd']; val+=.5*d*d+np.log(pr['sd']*np.sqrt(2*np.pi)); grad[j]+=d/pr['sd']
  elif pr['kind']=='ridge': val+=.5*pr['lam']*v*v; grad[j]+=pr['lam']*v
  else: raise ValueError('unknown prior')
 return float(val),grad

def hessian(f):
 p=f['point']; a=np.array(p['beta']+p['gamma']+[p['tau']],float); nb=len(p['beta']); ng=len(p['gamma']); H=np.zeros((len(a),len(a)))
 for i in range(len(a)):
  h=1e-5*(1+abs(a[i])); ap=a.copy(); am=a.copy(); ap[i]+=h; am[i]-=h
  def pp(v): return dict(beta=v[:nb].tolist(),gamma=v[nb:nb+ng].tolist(),tau=float(v[-1]))
  H[:,i]=(evaluate(f,pp(ap))[1]-evaluate(f,pp(am))[1])/(2*h)
 return H

def conditional_beta(f):
 X=np.array(f['X']); W=np.array(f['W']); y=np.array(f['y']); g=np.array(f['group']); p=f['point']; V=p['tau']**2*(g[:,None]==g[None,:])+np.diag(np.exp(2*W@p['gamma'])); c=cho_factor(V,lower=True); A=X.T@cho_solve(c,X); b=X.T@cho_solve(c,y)
 for pr in f['priors']:
  if pr['block']=='beta':
   j=pr['index']; precision=1/pr['sd']**2 if pr['kind']=='normal' else pr['lam']; A[j,j]+=precision; b[j]+=precision*(pr['mean'] if pr['kind']=='normal' else 0)
 return np.linalg.solve(A,b)

def run():
 import copy
 fs=[json.loads(p.read_text()) for p in sorted((P/'fixtures').glob('ri_*.json'))]; assert len(fs)==12 and sum(f['preflight'] for f in fs)==4
 maxima=dict(value=0.,gradient=0.,hessian=0.,conditional_gradient=0.)
 for f in fs:
  v,g=evaluate(f); e=f['expected']; H=hessian(f)
  for key,a,b in [('value',v,e['nll']),('gradient',g,e['gradient']),('hessian',H,e['hessian'])]:
   d=err(a,b); maxima[key]=max(maxima[key],d); assert d<LIMITS[key],(f['id'],key,d)
  q=copy.deepcopy(f['point']); q['beta']=conditional_beta(f).tolist(); z=evaluate(f,q)[1][:len(q['beta'])]; maxima['conditional_gradient']=max(maxima['conditional_gradient'],float(np.max(abs(z)))); assert max(abs(z))<1e-10
 # Direct independent diagonal boundary identity and variance-direction score.
 f=next(x for x in fs if x['point']['tau']==0); p=f['point']; y=np.array(f['y']); X=np.array(f['X']); W=np.array(f['W']); r=y-X@p['beta']; var=np.exp(2*W@p['gamma']); base=.5*np.sum(np.log(2*np.pi*var)+r*r/var); unpen=copy.deepcopy(f); unpen['priors']=[]; assert err(evaluate(unpen)[0],base)<1e-12
 groups=np.array(f['group']); K=(groups[:,None]==groups[None,:]); z=r/var; A=np.diag(1/var)-np.outer(z,z); score=.5*np.sum(A*K); assert abs(evaluate(f)[1][-1])<1e-14; assert err(hessian(f)[-1,-1],2*score)<1e-8
 # Mutants compare to frozen independent mpmath values, not freshly calculated expected values.
 f=next(x for x in fs if len(x['priors'])==2); expected=f['expected']['nll']
 variants=[]
 a=copy.deepcopy(f); a['priors'].pop(); variants.append(a)
 a=copy.deepcopy(f); a['priors'].append(copy.deepcopy(a['priors'][0])); variants.append(a)
 a=copy.deepcopy(f); a['priors'][0]['index']=1-a['priors'][0]['index']; variants.append(a)
 assert all(err(evaluate(a)[0],expected)>LIMITS['value'] for a in variants)
 assert err(evaluate(f)[0]+0.125,expected)>LIMITS['value']
 # Equal precision has identical derivatives but the normal density constant differs.
 a=copy.deepcopy(f); a['priors']=[dict(block='beta',index=0,kind='normal',mean=0.,sd=2.)]; b=copy.deepcopy(a); b['priors']=[dict(block='beta',index=0,kind='ridge',lam=0.25)]; va,ga=evaluate(a); vb,gb=evaluate(b); assert err(ga,gb)<1e-12 and err(hessian(a),hessian(b))<1e-9; assert abs((va-vb)-math.log(2*math.sqrt(2*math.pi)))<1e-12
 a['priors']=[dict(block='beta',index=0,kind='ridge',lam=0.)]; b['priors']=[]; assert err(evaluate(a)[0],evaluate(b)[0])<1e-15 and err(evaluate(a)[1],evaluate(b)[1])<1e-15
 print(json.dumps({'status':'PASS','fixtures':len(fs),'preflight':4,'max_errors':maxima,'mutations_rejected':['omitted','doubled','misindexed','constant_altered'],'python':sys.version,'numpy':np.__version__},indent=2))
 print('ORACLE_SELF_TEST_PASS')
if __name__=='__main__':
 p=argparse.ArgumentParser(); p.add_argument('--self-test',action='store_true',required=True); p.parse_args(); run()
