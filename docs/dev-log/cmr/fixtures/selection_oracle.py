"""Independent selection normalization checks on a finite reference distribution.
A deterministic fixture generator, not an approximation to a Gaussian integral.
"""
import itertools,json,importlib.util,argparse
from pathlib import Path
spec=importlib.util.spec_from_file_location('cmr_oracle',Path(__file__).with_name('oracle.py'))
mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
def first_capture_weight(phi,p,observed,eligibility,first):
    w=p[first]
    for t in range(eligibility,first):
        w*=phi[t]
        if observed[t]:w*=1-p[t]
    return w

def main():
    states=[{'mass':.5,'phi':[.95,.9,.85],'p':[.7,.6,.5,.4]},
            {'mass':.5,'phi':[.6,.55,.5],'p':[.2,.25,.3,.35]}]
    records=[]
    for f in range(4):
        masks=[True]*4
        weights=[first_capture_weight(s['phi'],s['p'],masks,0,f) for s in states]
        denom=sum(s['mass']*w for s,w in zip(states,weights))
        total=0
        for suffix in itertools.product([0,1],repeat=3-f):
            y=[0]*f+[1]+list(suffix)
            numerator=sum(s['mass']*w*mod.probability(y,s['phi'],s['p'],f) for s,w in zip(states,weights))
            likelihood=numerator/denom;total+=likelihood
            records.append({'history':y,'first':f+1,'numerator':numerator,'denominator':denom,'likelihood':likelihood})
        assert abs(total-1)<1e-14
        if f==3:assert records[-1]['likelihood']==1
    # When first-capture weights are constant, reference and marked distributions coincide.
    y=[1,0,1,0]; const=.3
    marked=sum(s['mass']*mod.probability(y,s['phi'],s['p']) for s in states)
    corrected=sum(s['mass']*const*mod.probability(y,s['phi'],s['p']) for s in states)/const
    assert abs(marked-corrected)<1e-15
    # A shared effect requires joint normalization for the vector of first-capture times.
    w=[.9,.1]; h=[.8,.2]
    joint=sum(.5*(a*b)**2 for a,b in zip(w,h))/sum(.5*a*a for a in w)
    product=(sum(.5*a*b for a,b in zip(w,h))/sum(.5*a for a in w))**2
    assert abs(joint-product)>.08
    output={'scope':'finite-reference-distribution deterministic selection oracle; not Gaussian integration, recovery or identification evidence','states':states,'histories':records,'shared_effect_counterexample':{'weights':w,'suffix_probabilities':h,'joint_conditioning':joint,'product_of_individual_conditionals':product}}
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,default=Path('selection-finite-reference.json'))
    parser.parse_args().output.write_text(json.dumps(output,indent=2)+'\n')
    print('CMR_SELECTION_ORACLE_OK: normalized 4 first-capture layouts; constant-weight reduction; final-first one; shared-effect counterexample')
if __name__=='__main__':main()
