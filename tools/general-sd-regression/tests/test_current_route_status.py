import csv
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'current_route_status.py'
BASE = Path('docs/dev-log/general-sd-regression')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_tsv(path, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]), delimiter='\t', lineterminator='\n')
        w.writeheader(); w.writerows(rows)


class RouteAuditTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name) / 'r'; self.root.mkdir()
        self.julia = Path(self.tmp.name) / 'julia'; self.julia.mkdir()
        self.rows = [dict(row_key='exact-a', engine='native', family_route='binomial', status='required'),
                     dict(row_key='exact-b', engine='native', family_route='binomial', status='required')]
        self.rows_path = self.root / BASE / 'required-rows.tsv'
        self.evidence_path = self.root / BASE / 'direct-sd-evidence.tsv'
        write_tsv(self.rows_path, self.rows)
        (self.root / 'R').mkdir(); (self.root / 'R/a.R').write_text('current\n')
        (self.root / 'R/drmTMB.R').write_text('builder\n')
        (self.root / 'src').mkdir(exist_ok=True)
        (self.root / 'src/drmTMB.cpp').write_text('#include "kernel.h"\n')
        (self.root / 'src/kernel.h').write_text('#include "nested.h"\n')
        (self.root / 'src/nested.h').write_text('kernel\n')
        (self.julia / 'src').mkdir()
        for name in ('binomial.jl', 'binomial_sd_regression.jl', 'adaptive_ghq.jl', 'gaussian_lss.jl', 'gaussian_core.jl', 'bridge.jl'):
            (self.julia / 'src' / name).write_text('Julia kernel\n')
        (self.root / 'test.R').write_text('test\n')
        (self.root / 'receipt.json').write_text('{"review_status":"unreviewed"}')
        (self.root / 'manifest.json').write_text(json.dumps({'files': [
            {'file':'R/a.R','sha256':sha(self.root / 'R/a.R')},
            {'file':'test.R','sha256':sha(self.root / 'test.R')}]}))
        self.rec = dict(row_key='exact-a', evidence_id='e1', evidence_grade='focused_test',
            receipt_path='receipt.json', receipt_sha256=sha(self.root/'receipt.json'),
            source_manifest_path='manifest.json', source_manifest_sha256=sha(self.root/'manifest.json'),
            test_path='test.R', test_sha256=sha(self.root/'test.R'), test_command='test',
            result_summary='pass', review_status='unreviewed')
        write_tsv(self.evidence_path, [self.rec])

    def tearDown(self): self.tmp.cleanup()

    def run_cli(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), '--root', str(self.root), '--julia-root', str(self.julia), *args], capture_output=True, text=True)

    def table(self):
        with (self.root / BASE / 'current-route-status.tsv').open() as f: return list(csv.DictReader(f, delimiter='\t'))

    def test_exact_join_preserves_rows_without_promoting_unlinked_or_unreviewed(self):
        p = self.run_cli(); self.assertEqual(p.returncode, 0, p.stderr)
        a,b = self.table(); self.assertEqual([a['row_key'],b['row_key']], ['exact-a','exact-b'])
        self.assertEqual(a['receipt_link'], 'linked'); self.assertEqual(b['receipt_link'], 'unlinked')
        audit=json.loads((self.root/BASE/'current-route-source-audit.json').read_text())
        self.assertEqual(audit['counts']['linked_rows'], 1); self.assertEqual(audit['counts']['unlinked_rows'], 1)
        self.assertTrue(audit['records'][0]['manifest_test_bound'])
        self.assertEqual(b['implementation'], 'unknown'); self.assertEqual(b['source_admission'], 'unknown')
        self.assertEqual(a['independent_review'], 'unreviewed'); self.assertEqual(a['exact_source_runtime'], 'unknown')

    def test_duplicate_required_key_rejected(self):
        write_tsv(self.rows_path, [self.rows[0], self.rows[0]])
        self.assertNotEqual(self.run_cli().returncode, 0)

    def test_stale_source_never_becomes_current_runtime(self):
        (self.root/'R/a.R').write_text('changed\n')
        self.assertEqual(self.run_cli().returncode, 0)
        self.assertEqual(self.table()[0]['exact_source_runtime'], 'unknown')
        audit = json.loads((self.root/BASE/'current-route-source-audit.json').read_text())
        self.assertIn('mismatch', json.dumps(audit))

    def test_julia_path_mapping_and_unverified_absolute_path(self):
        (self.julia/'src').mkdir(exist_ok=True); (self.julia/'src/a.jl').write_text('julia\n')
        manifest = {'files':[{'file':'DRModels.jl@87a371a66/src/a.jl','sha256':sha(self.julia/'src/a.jl')},
                             {'file':'DRModels.jl worktree general-sd-julia (HEAD abc): src/a.jl','sha256':sha(self.julia/'src/a.jl')},
                             {'file':'/unrelated/private/source.R','sha256':'0'*64},
                             {'file':'test.R','sha256':sha(self.root/'test.R')}]}
        (self.root/'manifest.json').write_text(json.dumps(manifest))
        self.rec['source_manifest_sha256']=sha(self.root/'manifest.json'); write_tsv(self.evidence_path,[self.rec])
        self.assertEqual(self.run_cli().returncode,0)
        audit=json.loads((self.root/BASE/'current-route-source-audit.json').read_text())
        s=json.dumps(audit); self.assertIn('unverified_absolute',s)
        entry=audit['records'][0]['manifest_entries'][0]
        self.assertEqual(entry['mapped'], 'julia/src/a.jl'); self.assertEqual(entry['state'], 'match')
        self.assertEqual(audit['records'][0]['manifest_entries'][1]['state'], 'match')

    def test_manifest_test_binding_requires_verified_exact_mapped_path(self):
        # Identical bytes at a suffix-matching path are not the recorded test.
        (self.root / 'unrelated').mkdir()
        (self.root / 'unrelated/test.R').write_bytes((self.root / 'test.R').read_bytes())
        for path in ('unrelated/test.R', '/unmapped/private/test.R'):
            with self.subTest(path=path):
                (self.root / 'manifest.json').write_text(json.dumps({'files': [
                    {'file': path, 'sha256': sha(self.root / 'test.R')}]}))
                self.rec['source_manifest_sha256'] = sha(self.root / 'manifest.json')
                write_tsv(self.evidence_path, [self.rec])
                self.assertEqual(self.run_cli().returncode, 0)
                audit = json.loads((self.root / BASE / 'current-route-source-audit.json').read_text())
                self.assertFalse(audit['records'][0]['manifest_test_bound'])

    def test_check_detects_row_loss_and_source_change(self):
        self.assertEqual(self.run_cli().returncode,0)
        self.assertEqual(self.run_cli('--check').returncode,0)
        path=self.root/BASE/'current-route-status.tsv'; lines=path.read_text().splitlines(keepends=True)
        path.write_text(''.join(lines[:-1])); self.assertNotEqual(self.run_cli('--check').returncode,0)
        self.assertEqual(self.run_cli().returncode,0)
        (self.root/'R/a.R').write_text('changed\n')
        self.assertNotEqual(self.run_cli('--check').returncode,0)

    def test_unknown_evidence_key_is_rejected(self):
        self.rec['row_key']='exact-c'; write_tsv(self.evidence_path,[self.rec])
        self.assertNotEqual(self.run_cli().returncode,0)

    def test_compiled_artifacts_do_not_change_source_snapshot(self):
        self.assertEqual(self.run_cli().returncode, 0)
        (self.root / 'src').mkdir(exist_ok=True)
        (self.root / 'src/drmTMB.so').write_bytes(b'compiled-library')
        (self.root / 'src/drmTMB.o').write_bytes(b'compiled-object')
        self.assertEqual(self.run_cli('--check').returncode, 0)

    def test_manifest_symlink_cannot_escape_selected_roots(self):
        outside = Path(self.tmp.name) / 'outside.R'
        outside.write_text('outside the selected source trees\n')
        (self.root / 'R/alias.R').symlink_to(outside)
        (self.root / 'manifest.json').write_text(json.dumps({'files': [
            {'file': 'R/alias.R', 'sha256': sha(outside)}]}))
        self.rec['source_manifest_sha256'] = sha(self.root / 'manifest.json')
        write_tsv(self.evidence_path, [self.rec])
        self.assertEqual(self.run_cli().returncode, 0)
        audit = json.loads((self.root / BASE / 'current-route-source-audit.json').read_text())
        self.assertEqual(audit['records'][0]['manifest_entries'][0]['state'],
                         'unverified_path')

    def overlay(self):
        return {'schema_version': 1, 'adjudications': [{
            'row_key': 'exact-a',
            'scope': {'interfaces': ['R/native'], 'estimator': 'ML',
                      'response': 'observed', 'sd_rhs': 'group-constant',
                      'limits': ['one scalar intercept']},
            'source_pins': [{'tree': 'r', 'path': 'R/a.R',
                             'sha256': sha(self.root / 'R/a.R'), 'lines': [1, 1]}] + [
                {'tree': 'r', 'path': name, 'sha256': sha(self.root / name), 'lines': [1, 1]}
                for name in ('R/drmTMB.R', 'src/drmTMB.cpp', 'src/kernel.h', 'src/nested.h')],
            'source_admission': {'state': 'admitted_scoped', 'reason': 'Exact route admitted.'},
            'implementation': {'state': 'implemented_scoped', 'reason': 'Matching likelihood.'},
            'next_task': 'S4-current-example-runtime'}]}

    def run_overlay(self, obj):
        path = self.root / 'adjudications.json'
        path.write_text(json.dumps(obj))
        return self.run_cli('--adjudications', str(path))

    def test_overlay_only_grants_scoped_source_fields(self):
        self.assertEqual(self.run_overlay(self.overlay()).returncode, 0)
        a, b = self.table()
        self.assertEqual(a['source_admission'], 'admitted_scoped')
        self.assertEqual(a['implementation'], 'implemented_scoped')
        evidence = json.loads(a['source_admission_evidence'])
        self.assertEqual(evidence['scope']['interfaces'], ['R/native'])
        self.assertEqual(evidence['source_pins'][0]['sha256'], sha(self.root / 'R/a.R'))
        self.assertEqual(evidence['next_task'], 'S4-current-example-runtime')
        self.assertEqual(len(evidence['overlay_sha256']), 64)
        for name in ('exact_source_runtime', 'public_output_contract', 'docs_example', 'fit', 'serialization'):
            self.assertEqual(a[name], 'unknown')
        self.assertEqual(a['calibration'], 'deferred')
        self.assertEqual(a['independent_review'], 'unreviewed')
        self.assertEqual(b['implementation'], 'unknown')

    def test_overlay_stale_and_missing_pins_leave_source_unknown(self):
        obj = self.overlay()
        for mode in ('stale', 'missing'):
            with self.subTest(mode=mode):
                if mode == 'stale':
                    (self.root / 'R/a.R').write_text('changed\n')
                else:
                    (self.root / 'R/a.R').unlink()
                self.assertEqual(self.run_overlay(obj).returncode, 0)
                a = self.table()[0]
                self.assertEqual(a['source_admission'], 'unknown')
                self.assertEqual(a['implementation'], 'unknown')
                self.assertIn(mode, a['source_admission_reason'])

    def test_overlay_shortened_stale_source_is_unknown_not_an_invalid_bound(self):
        (self.root / 'R/a.R').write_text('first\nsecond\n')
        obj = self.overlay(); obj['adjudications'][0]['source_pins'][0]['lines'] = [1, 2]
        (self.root / 'R/a.R').write_text('shortened\n')
        p = self.run_overlay(obj)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(self.table()[0]['implementation'], 'unknown')

    def test_no_overlay_preserves_conservative_schema_and_states(self):
        self.assertEqual(self.run_cli().returncode, 0)
        audit = json.loads((self.root / BASE / 'current-route-source-audit.json').read_text())
        self.assertNotIn('adjudications_sha256', audit['inputs'])
        self.assertNotIn('source_adjudications', audit)
        for row in self.table():
            self.assertEqual(row['source_admission'], 'unknown')
            self.assertEqual(row['implementation'], 'unknown')
            self.assertEqual(row['source_admission_evidence'], '')

    def test_overlay_requires_complete_nonempty_pin_schema(self):
        for mode in ('empty', 'missing', 'tree', 'hash', 'extra'):
            with self.subTest(mode=mode):
                obj = self.overlay(); item = obj['adjudications'][0]
                if mode == 'empty': item['source_pins'] = []
                elif mode == 'missing': del item['source_pins'][0]['sha256']
                elif mode == 'tree': item['source_pins'][0]['tree'] = 'other'
                elif mode == 'hash': item['source_pins'][0]['sha256'] = 'not-a-hash'
                else: item['source_pins'][0]['runtime'] = 'pass'
                self.assertNotEqual(self.run_overlay(obj).returncode, 0)

    def test_overlay_rejects_invalid_rows_and_forbidden_fields(self):
        for mode in ('unknown', 'missing', 'duplicate', 'runtime', 'scope'):
            with self.subTest(mode=mode):
                obj = self.overlay(); item = obj['adjudications'][0]
                if mode == 'unknown': item['row_key'] = 'not-in-universe'
                elif mode == 'missing': del item['row_key']
                elif mode == 'duplicate': obj['adjudications'].append(item.copy())
                elif mode == 'runtime': item['exact_source_runtime'] = {'state': 'pass'}
                else: item['scope']['interfaces'] = ['direct Julia']
                self.assertNotEqual(self.run_overlay(obj).returncode, 0)

    def test_julia_overlay_retains_bridge_and_direct_interface_qualification(self):
        self.rows[0]['engine'] = 'Julia'; write_tsv(self.rows_path, self.rows)
        (self.root / 'R/julia-bridge.R').write_text('bridge\n')
        obj = self.overlay(); item = obj['adjudications'][0]
        item['scope']['interfaces'] = ['R/Julia bridge', 'direct Julia']
        item['source_pins'].extend([
            {'tree': 'julia', 'path': 'src/' + name, 'sha256': sha(self.julia / 'src' / name), 'lines': [1, 1]}
            for name in ('binomial.jl', 'binomial_sd_regression.jl', 'adaptive_ghq.jl', 'gaussian_lss.jl', 'gaussian_core.jl', 'bridge.jl')])
        item['source_pins'].append({'tree': 'r', 'path': 'R/julia-bridge.R',
                                   'sha256': sha(self.root / 'R/julia-bridge.R'), 'lines': [1, 1]})
        p = self.run_overlay(obj); self.assertEqual(p.returncode, 0, p.stderr)
        evidence = json.loads(self.table()[0]['implementation_evidence'])
        self.assertEqual(evidence['scope']['interfaces'], ['R/Julia bridge', 'direct Julia'])
        self.assertTrue(all(p['state'] == 'match' for p in evidence['source_pins']))
        (self.julia / 'src/binomial.jl').write_text('changed\n')
        self.assertEqual(self.run_overlay(obj).returncode, 0)
        self.assertEqual(self.table()[0]['implementation'], 'unknown')

    def test_overlay_requires_native_builder_kernel_and_recursive_includes(self):
        for missing in ('R/drmTMB.R', 'src/drmTMB.cpp', 'src/kernel.h', 'src/nested.h'):
            with self.subTest(missing=missing):
                obj = self.overlay()
                item = obj['adjudications'][0]
                item['source_pins'] = [p for p in item['source_pins'] if p['path'] != missing]
                self.assertNotEqual(self.run_overlay(obj).returncode, 0)

    def test_overlay_stale_kernel_withholds_implementation(self):
        obj = self.overlay()
        (self.root / 'src/nested.h').write_text('changed kernel\n')
        self.assertEqual(self.run_overlay(obj).returncode, 0)
        row = self.table()[0]
        self.assertEqual(row['implementation'], 'unknown')
        self.assertIn('stale', row['implementation_reason'])

    def test_julia_interfaces_cannot_be_granted_by_only_r_or_arbitrary_julia_source(self):
        self.rows[0]['engine'] = 'Julia'; write_tsv(self.rows_path, self.rows)
        for interface in ('direct Julia', 'R/Julia bridge'):
            with self.subTest(interface=interface):
                obj = self.overlay(); item = obj['adjudications'][0]
                item['scope']['interfaces'] = [interface]
                item['source_pins'].append({'tree': 'julia', 'path': 'src/gaussian_core.jl',
                    'sha256': sha(self.julia / 'src/gaussian_core.jl'), 'lines': [1, 1]})
                self.assertNotEqual(self.run_overlay(obj).returncode, 0)

    def test_overlay_rejects_escaping_paths_and_invalid_line_bounds(self):
        outside = Path(self.tmp.name) / 'outside.R'; outside.write_text('outside\n')
        (self.root / 'R/alias.R').symlink_to(outside)
        for path, lines in [('../outside.R', [1, 1]), ('/tmp/source.R', [1, 1]),
                            ('R/alias.R', [1, 1]), ('R/a.R', [0, 1]),
                            ('R/a.R', [1, 2]), ('R/a.R', [True, 1])]:
            with self.subTest(path=path, lines=lines):
                obj = self.overlay(); obj['adjudications'][0]['source_pins'][0].update(path=path, lines=lines)
                self.assertNotEqual(self.run_overlay(obj).returncode, 0)

if __name__ == '__main__':
    result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(RouteAuditTests))
    if result.wasSuccessful() and result.testsRun: print('CURRENT_ROUTE_AUDIT_TESTS_PASS')
    sys.exit(not result.wasSuccessful() or not result.testsRun)
