#!/usr/bin/env python3
"""Independent dense Gaussian crossed-random-intercept oracle; no package imports.
Parameter order beta0,beta_x,alpha,gamma,log(sd_site),log(sd_observer).
"""
import hashlib, json, math, pathlib, platform
import numpy as np
from scipy.optimize import minimize
from scipy.special import gammaln

ROOT = pathlib.Path(__file__).resolve().parent
XVAL = np.array([-1.40,-1.05,-.88,-.63,-.37,-.14,.11,.29,.48,.72,1.03,1.41])
SITE = np.array([0,0,1,1,1,1,2,2,2,2,2,2])
OBS = np.array([0,1,0,1,2,2,0,1,1,2,2,2])
SITE_EFFECT = np.array([-.95,.30,.78]); OBS_EFFECT = np.array([.83,-.69,.25])
RESIDUAL = np.array([-.65,.44,-.24,.71,-1.04,.30,.51,-.42,.94,-.37,.07,-.61])
X = np.column_stack([np.ones(len(XVAL)), XVAL])
K = [(g[:,None] == g[None,:]).astype(float) for g in (SITE, OBS)]
Y = {str(s): .8 + .45*XVAL + s*(SITE_EFFECT[SITE] + .72*OBS_EFFECT[OBS]) + np.exp(-.35+.21*XVAL)*RESIDUAL for s in (0.,.03,.6)}
POINTS = np.array([[.6,.3,-.4,.1,-1.2,-.3],[1.,.5,-.1,-.2,-2.,-.8],[.2,-.15,.15,.35,-.4,-1.4],[.9,.7,-.6,.25,-3.,-2.],[.4,.2,.25,-.1,.1,-.7],[1.2,-.3,-.2,.05,-.9,.35]])
PRIORS = [(2.,3.),(3.5,1.7)]
FIXED = {0:(.25,1.4),3:(-.1,.7)}

def objective(t,y,which=(),fixed=False,mutation=None,derivatives=True):
    b=t[:2]; a,c,e1,e2=t[2:]; z=np.exp(2*(a+c*XVAL)); s=np.exp(2*np.array([e1,e2]));
    V=np.diag(z)+s[0]*K[0]+s[1]*K[1]; sign,ld=np.linalg.slogdet(V)
    assert sign > 0
    W=np.linalg.inv(V); r=y-X@b; q=W@r; f=.5*(len(y)*math.log(2*math.pi)+ld+r@q)
    D=[np.diag(2*z),np.diag(2*z*XVAL),2*s[0]*K[0],2*s[1]*K[1]]
    DD=[[np.zeros_like(V) for j in range(4)] for i in range(4)]
    DD[0][0]=np.diag(4*z); DD[0][1]=DD[1][0]=np.diag(4*z*XVAL); DD[1][1]=np.diag(4*z*XVAL**2)
    DD[2][2]=4*s[0]*K[0]; DD[3][3]=4*s[1]*K[1]
    g=np.zeros(6); H=np.zeros((6,6)); g[:2]=-X.T@q; H[:2,:2]=X.T@W@X
    for i in range(4):
        A=D[i]; g[i+2]=.5*np.trace(W@A)-.5*q@A@q
        H[:2,i+2]=H[i+2,:2]=X.T@W@A@q
        for j in range(4):
            B=D[j]; C=DD[i][j]
            H[i+2,j+2]=.5*(-np.trace(W@B@W@A)+np.trace(W@C))+q@B@W@A@q-.5*q@C@q
    for i in which:
        shape,rate=PRIORS[i]; eta=t[4+i]; tau=math.exp(eta)
        if mutation=='wrong_target': eta=t[5-i]; tau=math.exp(eta)
        if mutation=='swap_shape_rate': shape,rate=rate,shape
        p=rate*tau-(shape-1)*eta-shape*math.log(rate)+gammaln(shape)
        if mutation=='omit_normalizer': p=rate*tau-(shape-1)*eta
        factor=0 if mutation=='omit' else 2 if mutation=='double' else len(np.unique((SITE,OBS)[i])) if mutation=='per_group' else 1
        f+=factor*p; g[4+i]+=factor*(rate*tau-(shape-1)); H[4+i,4+i]+=factor*rate*tau
        if mutation=='jacobian': f-=eta
    if fixed:
        for i,(mean,sd) in FIXED.items():
            f+=.5*((t[i]-mean)/sd)**2 + math.log(sd*math.sqrt(2*math.pi)); g[i]+=(t[i]-mean)/sd**2; H[i,i]+=1/sd**2
    return (float(f),g,H) if derivatives else float(f)

def fdgrad(f,t,h):
    out=np.empty(len(t))
    for i in range(len(t)):
        d=np.zeros(len(t)); d[i]=h; out[i]=(f(t+d)-f(t-d))/(2*h)
    return out

def fdhess(f,t,h):
    n=len(t); out=np.empty((n,n)); base=f(t)
    for i in range(n):
        di=np.zeros(n); di[i]=h
        out[i,i]=(f(t+di)-2*base+f(t-di))/h**2
        for j in range(i):
            dj=np.zeros(n); dj[j]=h
            out[i,j]=out[j,i]=(f(t+di+dj)-f(t+di-dj)-f(t-di+dj)+f(t-di-dj))/(4*h*h)
    return out

def main():
    cases=[('none',(),False),('site',(0,),False),('observer',(1,),False),('both',(0,1),False),('mixed',(0,1),True)]
    records=[]; maxg=maxh=0.; gstep=1e-5; hstep=2e-4
    for data,y in Y.items():
        for name,which,fixed in cases:
            for p in POINTS:
                value,g,H=objective(p,y,which,fixed); f=lambda tt: objective(tt,y,which,fixed,derivatives=False)
                gn=fdgrad(f,p,gstep); hn=fdhess(f,p,hstep)
                ge=float(np.max(np.abs(g-gn))); he=float(np.max(np.abs(H-hn)/np.maximum(1.,np.abs(H))))
                maxg=max(maxg,ge); maxh=max(maxh,he)
                records.append(dict(dataset=data,case=name,theta=p.tolist(),objective=value,gradient=g.tolist(),hessian=H.tolist()))
    assert maxg<=1e-6,("gradient",maxg)
    assert maxh<=1e-5,("hessian",maxh)
    neg={}
    p=POINTS[0]; y=Y['0.03']; ref=objective(p,y,(0,),derivatives=False)
    for mutation in ('wrong_target','swap_shape_rate','omit_normalizer','omit','double','per_group','jacobian'):
        m=objective(p,y,(0,),mutation=mutation,derivatives=False); delta=abs(m-ref); assert delta>1e-5,(mutation,delta); neg[mutation]=delta
    # Exact unpenalized zero variance is calculated independently, without log(0).
    r=y-X@p[:2]; v=np.exp(2*(p[2]+p[3]*XVAL)); V0=np.diag(v); s,ld=np.linalg.slogdet(V0)
    zero=.5*(len(y)*math.log(2*math.pi)+ld+r@np.linalg.solve(V0,r)); assert np.isfinite(zero)
    assert objective(np.r_[p[:4],-25.,p[5]],y,(0,),derivatives=False)>objective(np.r_[p[:4],-10.,p[5]],y,(0,),derivatives=False)
    shape,rate=PRIORS[0]; anchor=rate*.8-(shape-1)*math.log(.8)-shape*math.log(rate)+gammaln(shape)
    assert abs(anchor-0.42591897397799006)<1e-12
    fits=[]
    for data,y in Y.items():
        for name,which,fixed in cases[1:]:
            f=lambda t: objective(t,y,which,fixed)[:2]
            # L-BFGS-B keeps finite values and explicitly identifies floor contact.
            bounds=[(None,None)]*4+[(-18.,5.),(-18.,5.)]
            opt=minimize(f,POINTS[0],jac=True,method='L-BFGS-B',bounds=bounds,options={'maxiter':5000,'ftol':1e-14,'gtol':1e-9,'maxls':50})
            value,grad,H=objective(opt.x,y,which,fixed); eig=np.linalg.eigvalsh(H); active=bool(np.any(opt.x[4:]<=-17.99))
            fits.append(dict(dataset=data,case=name,theta=opt.x.tolist(),objective=value,score_inf=float(np.max(np.abs(grad))),success=bool(opt.success),message=str(opt.message),floor_contact=active,hessian_min_eigenvalue=float(eig[0])))
    out={'schema':'two-ri-dense-oracle-v1','parameter_order':['beta_intercept','beta_x','alpha','gamma','log_sd_site','log_sd_observer'],'site':SITE.tolist(),'observer':OBS.tolist(),'x':XVAL.tolist(),'site_effect_draws':SITE_EFFECT.tolist(),'observer_effect_draws':OBS_EFFECT.tolist(),'residual_draws':RESIDUAL.tolist(),'response':{k:v.tolist() for k,v in Y.items()},'generation':'beta=(0.8,0.45), residual sd=exp(-0.35+0.21*x); site and observer draws multiplied by generating sd and 0.72*generating sd respectively','sd_gamma_shape_rate':PRIORS,'fixed_normal_mean_sd':{str(k):v for k,v in FIXED.items()},'finite_difference_steps':{'gradient':gstep,'hessian':hstep},'max_gradient_absolute_error':maxg,'max_hessian_scaled_error':maxh,'gamma_anchor_tau_0.8':anchor,'unpenalized_zero_both_sd':float(zero),'negative_control_objective_differences':neg,'records':records,'fits':fits,'runtime':{'python':platform.python_version(),'numpy':np.__version__}}
    path=ROOT/'frozen.json'; path.write_text(json.dumps(out,indent=2,allow_nan=False)+'\n'); print('ORACLE_PASS',len(records),'points',len(fits),'fits','grad',maxg,'hess',maxh,'negative_controls',len(neg)); print('SHA256',hashlib.sha256(path.read_bytes()).hexdigest())
if __name__=='__main__': main()
