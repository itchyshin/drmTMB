#!/usr/bin/env python3
"""Build a conservative, exact-row view of historical SD evidence and source bytes."""
import argparse
import collections
import csv
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import sys

BASE = Path('docs/dev-log/general-sd-regression')
FIELDS = ('source_admission', 'implementation', 'exact_source_runtime', 'receipt_link',
          'independent_review', 'public_output_contract', 'docs_example', 'calibration')
OUTPUTS = ('fit', 'recovery_oracle', 'simulation', 'sd_prediction', 'response_prediction',
           'extraction', 'serialization', 'refit_profile_bootstrap')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_table(path):
    with path.open(encoding='utf-8', newline='') as f:
        reader = csv.DictReader(f, delimiter='\t')
        if not reader.fieldnames or len(reader.fieldnames) != len(set(reader.fieldnames)):
            raise ValueError(f'invalid header: {path}')
        rows = list(reader)
        if any(None in row or any(v is None for v in row.values()) for row in rows):
            raise ValueError(f'malformed table: {path}')
        return reader.fieldnames, rows


def resolve_recorded(value, root, julia):
    """Only recognize explicit Julia checkout markers; never guess arbitrary absolute paths."""
    def bounded(base, tail, label):
        path = base.joinpath(*tail)
        if not path.resolve().is_relative_to(base.resolve()):
            return None, 'unverified_path'
        return path, label

    s = value.replace('\\', '/')
    if s.startswith('DRModels.jl worktree general-sd-julia') and ': ' in s:
        s = 'DRModels.jl/' + s.rsplit(': ', 1)[1]
    p = PurePosixPath(s)
    if '..' in p.parts:
        return None, 'unverified_path'
    for i, part in enumerate(p.parts):
        if part in ('DRModels.jl', 'DRM.jl', 'drmodels-main', 'general-sd-julia') or part.startswith(('DRModels.jl@', 'DRM.jl@')):
            tail = p.parts[i+1:]
            if tail:
                return bounded(julia, tail, 'julia/' + '/'.join(tail))
    if p.is_absolute():
        for base, label in ((root, 'r'), (julia, 'julia')):
            try:
                tail = Path(s).relative_to(base)
                return bounded(base, tail.parts, label + '/' + tail.as_posix())
            except ValueError:
                pass
        return None, 'unverified_absolute'
    return bounded(root, p.parts, 'r/' + s)


def entries(obj):
    if isinstance(obj, dict):
        path = obj.get('file', obj.get('path'))
        if isinstance(path, str) and isinstance(obj.get('sha256'), str):
            yield path, obj['sha256']
        for x in obj.values():
            yield from entries(x)
    elif isinstance(obj, list):
        for x in obj:
            yield from entries(x)


def manifest_entries(path):
    text = path.read_text(encoding='utf-8')
    try:
        return list(entries(json.loads(text)))
    except json.JSONDecodeError:
        pass
    if path.suffix.lower() == '.csv':
        rows = list(csv.DictReader(io.StringIO(text)))
        if rows and 'sha256' in rows[0]:
            return [(r.get('file', r.get('path', '')), r['sha256']) for r in rows]
    out = []
    for line in text.splitlines():
        parts = line.strip().split(maxsplit=1)
        if len(parts) == 2 and len(parts[0]) == 64:
            out.append((parts[1].lstrip('*'), parts[0]))
    return out


def snapshot(base, directories):
    result = {}
    for directory in directories:
        path = base / directory
        if path.exists():
            for f in sorted(path.rglob('*')):
                is_source = (f.suffix.lower() in
                             {'.r', '.jl', '.c', '.cc', '.cpp', '.cxx', '.h', '.hpp', '.f', '.f90'}
                             or f.name.startswith('Makevars'))
                if is_source and f.is_file() and not f.is_symlink():
                    result[f.relative_to(base).as_posix()] = digest(f)
    return result


# Explicit coverage for the first article candidates only. Adding a family or
# changing its implementation requires a reviewed dependency map, not any .jl pin.
JULIA_SOURCE_COVERAGE = {
    'binomial': {'src/binomial.jl', 'src/binomial_sd_regression.jl',
                 'src/adaptive_ghq.jl', 'src/gaussian_lss.jl'},
    'poisson': {'src/poisson.jl', 'src/adaptive_ghq.jl', 'src/gaussian_lss.jl'},
    'gamma': {'src/gamma.jl', 'src/sparse_laplace_glmm.jl', 'src/gaussian_lss.jl'},
}


def require_source_coverage(row, interfaces, pins, root):
    """Reject absent implementation bindings; matching pins still need human review."""
    identities = {(p['tree'], p['path']) for p in pins}
    states = {(p['tree'], p['path']): p['state'] for p in pins}
    required = set()
    if 'R/native' in interfaces:
        required.update({('r', 'R/drmTMB.R'), ('r', 'src/drmTMB.cpp')})
        # A changed/missing pinned source already withholds the grant. Traverse
        # only matching bytes, whose local includes define this checked closure.
        pending = ['src/drmTMB.cpp']; visited = set()
        while pending:
            rel = pending.pop()
            if rel in visited: continue
            visited.add(rel)
            if states.get(('r', rel)) != 'match': continue
            source = root / rel
            for name in re.findall(r'^\s*#\s*include\s*"([^"\n]+)"',
                                   source.read_text(encoding='utf-8'), re.MULTILINE):
                target = (source.parent / name).resolve()
                if not target.is_relative_to((root / 'src').resolve()):
                    raise ValueError('native local include escapes src')
                local = target.relative_to(root.resolve()).as_posix()
                required.add(('r', local)); pending.append(local)
    if 'direct Julia' in interfaces or 'R/Julia bridge' in interfaces:
        family = row.get('family_route')
        if family not in JULIA_SOURCE_COVERAGE:
            raise ValueError(f'no reviewed Julia source coverage for family: {family}')
        required.update(('julia', p) for p in JULIA_SOURCE_COVERAGE[family])
    if 'R/Julia bridge' in interfaces:
        required.update({('r', 'R/julia-bridge.R'), ('julia', 'src/bridge.jl')})
    absent = sorted(required - identities)
    if absent:
        raise ValueError('insufficient source pin coverage: ' +
                         ', '.join(f'{tree}/{path}' for tree, path in absent))


def load_adjudications(path, root, julia, rows):
    """Validate scoped source claims only; never infer execution from source pins."""
    if path is None:
        return {}, None
    obj = json.loads(path.read_text(encoding='utf-8'))

    def fields(value, required, label):
        if not isinstance(value, dict) or set(value) != set(required):
            raise ValueError(f'invalid or unsupported {label} fields')

    def nonempty(value):
        return isinstance(value, str) and bool(value.strip())

    fields(obj, ('schema_version', 'adjudications'), 'adjudication document')
    if type(obj['schema_version']) is not int or obj['schema_version'] != 1 or not isinstance(obj['adjudications'], list):
        raise ValueError('invalid adjudication schema')
    known = {r['row_key']: r for r in rows}
    result = {}
    overlay_hash = digest(path)
    for item in obj['adjudications']:
        fields(item, ('row_key', 'scope', 'source_pins', 'source_admission',
                      'implementation', 'next_task'), 'row adjudication')
        key = item['row_key']
        if not isinstance(key, str) or key not in known or key in result:
            raise ValueError(f'unknown or duplicate adjudication row: {key}')
        scope = item['scope']
        fields(scope, ('interfaces', 'estimator', 'response', 'sd_rhs', 'limits'), 'scope')
        interfaces = scope['interfaces']
        allowed = {'R/native'} if known[key]['engine'] == 'native' else {'R/Julia bridge', 'direct Julia'} if known[key]['engine'] == 'Julia' else set()
        if (not isinstance(interfaces, list) or not interfaces or
                any(not isinstance(x, str) or x not in allowed for x in interfaces) or
                len(interfaces) != len(set(interfaces))):
            raise ValueError(f'invalid interface qualification for {key}')
        if (any(not nonempty(scope[x]) for x in ('estimator', 'response', 'sd_rhs')) or
                not isinstance(scope['limits'], list) or not scope['limits'] or
                any(not nonempty(x) for x in scope['limits']) or not nonempty(item['next_task'])):
            raise ValueError('scope and next_task must be explicit and nonempty')
        for field, state in [('source_admission', 'admitted_scoped'), ('implementation', 'implemented_scoped')]:
            fields(item[field], ('state', 'reason'), field)
            if item[field]['state'] != state or not nonempty(item[field]['reason']):
                raise ValueError(f'invalid scoped {field} grant')
        pins = item['source_pins']
        if not isinstance(pins, list) or not pins:
            raise ValueError('source_pins must be nonempty')
        checked = []; identities = set()
        for pin in pins:
            fields(pin, ('tree', 'path', 'sha256', 'lines'), 'source pin')
            if pin['tree'] not in ('r', 'julia') or not nonempty(pin['path']):
                raise ValueError('invalid source pin tree or path')
            rel = PurePosixPath(pin['path'])
            if not rel.parts or rel.is_absolute() or '..' in rel.parts or '\\' in pin['path'] or str(rel) != pin['path']:
                raise ValueError('source pin path must be normalized and relative')
            identity = (pin['tree'], pin['path'])
            if identity in identities: raise ValueError('duplicate source pin')
            identities.add(identity)
            if not isinstance(pin['sha256'], str) or re.fullmatch(r'[0-9a-fA-F]{64}', pin['sha256']) is None:
                raise ValueError('invalid source pin SHA-256')
            bounds = pin['lines']
            if (not isinstance(bounds, list) or len(bounds) != 2 or
                    any(type(x) is not int for x in bounds) or not 1 <= bounds[0] <= bounds[1]):
                raise ValueError('invalid source pin line bounds')
            base = root if pin['tree'] == 'r' else julia
            source = base.joinpath(*rel.parts)
            if not source.resolve().is_relative_to(base.resolve()):
                raise ValueError('source pin escapes selected tree')
            actual = None
            if not source.is_file():
                state = 'missing'
            else:
                actual = digest(source)
                state = 'match' if actual.lower() == pin['sha256'].lower() else 'stale'
                # Line spans describe the pinned bytes, not a changed file.
                if state == 'match' and bounds[1] > len(source.read_text(encoding='utf-8').splitlines()):
                    raise ValueError('source pin line bounds exceed pinned file')
            checked.append(dict(pin, state=state, current_sha256=actual))
        require_source_coverage(known[key], interfaces, checked, root)
        result[key] = dict(item, source_pins=checked, overlay_sha256=overlay_hash)
    return result, overlay_hash


def build(root, julia, adjudications=None):
    root, julia = root.resolve(), julia.resolve()
    if not julia.is_dir(): raise ValueError(f'Julia root missing: {julia}')
    row_path, evidence_path = root/BASE/'required-rows.tsv', root/BASE/'direct-sd-evidence.tsv'
    columns, rows = read_table(row_path); _, records = read_table(evidence_path)
    keys = [r.get('row_key','') for r in rows]
    if not keys or any(not k for k in keys) or len(keys) != len(set(keys)):
        raise ValueError('required row keys must be nonempty and unique')
    adjudicated, overlay_hash = load_adjudications(adjudications, root, julia, rows)
    by_key = collections.defaultdict(list); identities=set(); known=set(keys)
    for rec in records:
        key=rec['row_key']; identity=(key,rec['evidence_id'])
        if key not in known or not identity[1] or identity in identities:
            raise ValueError(f'unknown or duplicate evidence identity: {identity}')
        identities.add(identity); by_key[key].append(rec)
    files = {}; details=[]
    def file_info(value, expected):
        path, mapped = resolve_recorded(value, root, julia)
        if path is None: return {'path':value, 'mapped':mapped, 'state':mapped, 'recorded_sha256':expected}
        if not path.is_file(): return {'path':value, 'mapped':mapped, 'state':'missing', 'recorded_sha256':expected}
        cachekey=str(path)
        if cachekey not in files: files[cachekey]=digest(path)
        actual=files[cachekey]
        return {'path':value, 'mapped':mapped, 'state':'match' if actual.lower()==expected.lower() else 'mismatch', 'recorded_sha256':expected, 'current_sha256':actual}
    for rec in records:
        detail={k:rec[k] for k in ('row_key','evidence_id','evidence_grade','review_status','test_command','result_summary')}
        for label, pfield, hfield in [('receipt','receipt_path','receipt_sha256'), ('manifest','source_manifest_path','source_manifest_sha256'), ('test','test_path','test_sha256')]:
            detail[label]=file_info(rec[pfield], rec[hfield])
        manifest,_=resolve_recorded(rec['source_manifest_path'],root,julia)
        source=[]
        if manifest and manifest.is_file():
            for path, sha in manifest_entries(manifest): source.append(file_info(path,sha))
        detail['manifest_entries']=source
        test = detail['test']
        detail['manifest_test_bound'] = (
            test['mapped'].startswith(('r/', 'julia/')) and
            any(x['mapped'] == test['mapped'] and
                x['recorded_sha256'].lower() == test['recorded_sha256'].lower()
                for x in source)
        )
        receipt,_=resolve_recorded(rec['receipt_path'],root,julia)
        detail['receipt_embedded_files']=[]
        detail['rerun_after_first_record']=None
        if receipt and receipt.is_file():
            try:
                obj=json.loads(receipt.read_text(encoding='utf-8'))
                if isinstance(obj,dict):
                    rerun=obj.get('rerun_after_first_record')
                    if rerun is not None: detail['rerun_after_first_record']=rerun
                    def embedded(x):
                        if isinstance(x,dict):
                            for k,v in x.items():
                                if isinstance(v,str) and k.endswith(('_path','_log')):
                                    h=x.get(k+'_sha256')
                                    if isinstance(h,str): yield v,h
                                yield from embedded(v)
                        elif isinstance(x,list):
                            for v in x: yield from embedded(v)
                    detail['receipt_embedded_files']=[file_info(p,h) for p,h in embedded(obj)]
            except (json.JSONDecodeError, UnicodeDecodeError): pass
        details.append(detail)
    add=[]
    for name in FIELDS + OUTPUTS:
        add.extend((name, name+'_evidence', name+'_reason'))
    if set(columns)&set(add): raise ValueError('generated fields collide with required columns')
    out=io.StringIO(newline=''); writer=csv.DictWriter(out,fieldnames=columns+add,delimiter='\t',lineterminator='\n'); writer.writeheader()
    for row in rows:
        linked=by_key.get(row['row_key'], []); ids=' | '.join(r['evidence_id'] for r in linked)
        x=dict(row)
        for name in FIELDS+OUTPUTS:
            x[name]='unknown'; x[name+'_evidence']=''; x[name+'_reason']='Needs exact-row adjudication and source-bound verification.'
        x.update(source_admission_reason='Historical status and base link are not current SD admission; inspect current route.',
                 implementation_reason='Inspect current source for this exact row; missing receipt is not missing implementation.',
                 exact_source_runtime_reason='Recorded bytes are compared in source audit; current runtime has not been independently adjudicated.',
                 receipt_link='linked' if linked else 'unlinked', receipt_link_evidence=ids,
                 receipt_link_reason='Exact row_key match in historical evidence table.' if linked else 'No exact row_key receipt; locate or run a row-specific test.',
                 independent_review=' | '.join(sorted(set(r['review_status'] for r in linked))) if linked else 'unknown',
                 independent_review_evidence=ids,
                 independent_review_reason='Record statuses retained; narrative review grants may not be machine-bound to rows and require independent adjudication.',
                 calibration='deferred', calibration_reason='G5 deferred; adjudicate any specifically verified older cell separately.')
        if row['row_key'] in adjudicated:
            claim = adjudicated[row['row_key']]
            evidence = {k: claim[k] for k in ('scope', 'source_pins', 'overlay_sha256', 'next_task')}
            problems = sorted(set(p['state'] for p in claim['source_pins'] if p['state'] != 'match'))
            for name in ('source_admission', 'implementation'):
                x[name+'_evidence'] = json.dumps(evidence, sort_keys=True, ensure_ascii=False)
                x[name+'_reason'] = (('Source pin ' + ', '.join(problems) + '; scoped grant withheld.')
                                    if problems else claim[name]['reason']) + ' Next task: ' + claim['next_task'] + '.'
                if not problems: x[name] = claim[name]['state']
        writer.writerow(x)
    families=sorted(set(r.get('family_route','') for r in rows))
    counts={'required_rows':len(rows),'records':len(records),'linked_rows':len(by_key),'unlinked_rows':len(rows)-len(by_key),'families':len(families)}
    audit={'schema_version':1,'scope':'Integrity and source-byte comparison only; scientific route adjudication remains open.',
        'inputs':{'required_rows_sha256':digest(row_path),'evidence_sha256':digest(evidence_path),
                  'generator_sha256':digest(Path(__file__).resolve())},
        'source_snapshots':{'r':snapshot(root,['R','src']),'julia':snapshot(julia,['src'])},
        'counts':counts,'families':families,'records':details,
        'limitations':['Manifest completeness is not established. A matching source file is not a runtime result or independent review.',
                       'Rerun metadata is preserved; its reported commit is not proof of complete tested source identity.',
                       'Absolute paths without an explicit selected-root mapping remain unverified.',
                       'Narrative review grants may not be machine-bound to exact rows.',
                       'Calibration is deferred pending exact-cell adjudication; G5 and D-342 remain deferred.']}
    if overlay_hash is not None:
        audit['inputs']['adjudications_sha256'] = overlay_hash
        audit['source_adjudications'] = list(adjudicated.values())
    summary=(f"# Current route evidence view\n\nThe frozen universe contains {len(rows)} rows across {len(families)} families. "
             f"The evidence table contains {len(records)} records linked to {len(by_key)} exact rows; {len(rows)-len(by_key)} rows have no exact link. "
             "These are evidence counts, not capability or completion counts.\n\n"
             "The table preserves the historical status and separates admission, implementation, runtime, receipt, review, outputs, documentation and calibration. "
             "The accompanying JSON compares recorded source, test and available receipt-file hashes with selected current trees. "
             "Matching bytes alone do not establish execution, admission or independent review. Unmapped absolute paths remain unverified.\n\n"
             "Current admission, implementation, runtime and output contracts require exact-row adjudication. "
             "An unlinked row is not evidence of missing implementation, including Student and skew-normal. "
             "Narrative reviews require row-level binding. Calibration is deferred pending a specific older-cell verification; G5 and D-342 remain deferred. "
             "This integrity view does not complete the scientific route audit.\n")
    if overlay_hash is not None:
        summary += (f"\nThe source overlay records {len(adjudicated)} scoped adjudications. "
                    "Only matching source pins can grant admission and implementation within their stated interfaces and limits; "
                    "runtime and output qualification remain separate.\n")
    return {BASE/'current-route-status.tsv':out.getvalue(), BASE/'article-capability-summary.md':summary,
            BASE/'current-route-source-audit.json':json.dumps(audit,indent=2,ensure_ascii=False,sort_keys=True)+'\n'}


def main():
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[2]); parser.add_argument('--julia-root',type=Path,required=True); parser.add_argument('--adjudications',type=Path); parser.add_argument('--check',action='store_true'); args=parser.parse_args()
    try:
        artifacts=build(args.root,args.julia_root,args.adjudications)
        for rel, content in artifacts.items():
            path=args.root/rel
            if args.check:
                if not path.is_file() or path.read_bytes()!=content.encode('utf-8'): raise ValueError(f'artifact differs: {rel}')
            else:
                path.parent.mkdir(parents=True,exist_ok=True); path.write_text(content,encoding='utf-8',newline='')
    except (ValueError, OSError, KeyError) as e:
        print(f'CURRENT_ROUTE_AUDIT_FAIL: {e}',file=sys.stderr); return 1
    print('CURRENT_ROUTE_AUDIT_PASS'); return 0

if __name__=='__main__': sys.exit(main())
