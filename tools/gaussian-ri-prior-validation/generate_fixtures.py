#!/usr/bin/env python3
"""One-time fixture construction: mpmath formula independent of numpy oracle."""
import json, math
from pathlib import Path
import mpmath as m
m.mp.dps=50
out=Path(__file__).parent/'fixtures'
for k in range(12):
 n=8+k%4; groups=[i//2 if k%2==0 else (0 if i<3 else 1 if i<5 else 2) for i in range(n)]; g=max(groups)+1
 x=[[-1+2*i/(n-1), float(i%2)] for i in range(n)]
 if k%3: x=[[1.,a] for a,b in x]
 w=[[1.] if k in (0,1) else [1., (i-(n-1)/2)/n] for i in range(n)]
 y=[round(0.6+0.45*x[i][1]+0.25*math.sin(i*1.7+k)+0.16*groups[i],10) for i in range(n)]
 beta=[0.4,-0.3]; gamma=[-0.1] if k in (0,1) else [-0.1,0.25]; tau=[0.,0.025,0.5,0.85][k%4]
 pri=[]
 if k%3 != 1: pri.append(dict(block='beta',index=k%2,mean=0.35,sd=0.8,kind='normal') if k%2==0 else dict(block='beta',index=k%2,lam=0.45,kind='ridge'))
 if k%3 != 0: pri.append(dict(block='gamma',index=(k//2)%len(gamma),mean=-0.22,sd=1.3,kind='normal') if k%2 else dict(block='gamma',index=(k//2)%len(gamma),lam=0.7,kind='ridge'))
 f=dict(raw_data=dict(y=y,x=[row[0] if k%3==0 else row[1] for row in x],f=['B' if i%2 else 'A' for i in range(n)],scale_x=[(i-(n-1)/2)/n for i in range(n)],group=groups), formula=dict(mean='y ~ 0 + x + I(as.numeric(f == \"B\"))' if k%3==0 else 'y ~ 1 + x', scale='~ 1' if len(gamma)==1 else '~ 1 + scale_x', random_intercept='(1 | group)', mean_columns=['x','I(as.numeric(f == B))'] if k%3==0 else ['(Intercept)','x'], scale_columns=['(Intercept)'] if len(gamma)==1 else ['(Intercept)','scale_x']),schema_version=1,id=f'ri_{k+1:02d}',preflight=k<4,description=['balanced_tau_zero','unbalanced_weak_tau','balanced_both_targets','unbalanced_positive_tau'][k] if k<4 else 'deterministic_case',y=y,X=x,W=w,group=groups,point=dict(beta=beta,gamma=gamma,tau=tau),priors=pri)
 def obj(*a):
  b=m.matrix(a[:2]); h=a[2:-1]; t=a[-1]; X=m.matrix(x); W=m.matrix(w); yy=m.matrix(y); r=yy-X*b
  V=m.matrix(n); 
  for i in range(n):
   for j in range(n): V[i,j]=t*t*(groups[i]==groups[j])+(m.exp(2*sum(W[i,l]*h[l] for l in range(len(gamma)))) if i==j else 0)
  L=m.cholesky(V); z=m.lu_solve(V,r)
  val=(n*m.log(2*m.pi)+2*sum(m.log(L[i,i]) for i in range(n))+(r.T*z)[0])/2
  for p in pri:
   v=a[p['index']+(0 if p['block']=='beta' else 2)]
   if p['kind']=='normal':
    sd=m.mpf(p['sd']); val+=(v-p['mean'])**2/(2*sd**2)+m.log(sd*m.sqrt(2*m.pi))
   else: val+=m.mpf(p['lam'])*v*v/2
  return val
 a=tuple(map(m.mpf,beta+gamma+[tau])); value=obj(*a); grad=[m.diff(lambda s: obj(*(a[:i]+(s,)+a[i+1:])),a[i]) for i in range(len(a))]; H=m.matrix(len(a))
 for i in range(len(a)):
  for j in range(len(a)):
   order=[0]*len(a); order[i]+=1; order[j]+=1; H[i,j]=m.diff(obj,a,tuple(order))
 f['expected']={'nll':float(value),'gradient':[float(z) for z in grad],'hessian':[[float(H[i,j]) for j in range(len(a))] for i in range(len(a))]}
 (out/(f['id']+'.json')).write_text(json.dumps(f,indent=2,sort_keys=True)+'\n')
