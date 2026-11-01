// Copy immutable planning templates into ignored run state. Never overwrite a run.
import { existsSync, mkdirSync, readFileSync, copyFileSync, constants } from "node:fs";
import { execFileSync } from "node:child_process";
import { resolve, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = process.cwd();
const source = fileURLToPath(new URL(".", import.meta.url));
const expected = resolve(root, "docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy");
if (resolve(source) !== expected || !existsSync(join(root, "DESCRIPTION"))) {
  throw new Error("Run stage.mjs from this plan's package root.");
}
const target = join(root, ".unlazy/temporal-ar1");
if (existsSync(target)) throw new Error("Runtime scope already exists; preserve it, do not restage.");
execFileSync("git", ["check-ignore", "--quiet", ".unlazy/temporal-ar1/GATES.md"], { cwd: root });
const files = ["GATES.md", ...Array.from({ length: 6 }, (_, n) => `gates/leaf-0${n + 1}.md`)];
for (const file of files) {
  if (!readFileSync(join(source, file), "utf8").includes("EVIDENCE: pending")) {
    throw new Error("Template is not a pristine pending ledger: " + file);
  }
}
mkdirSync(join(target, "gates"), { recursive: true });
for (const file of files) copyFileSync(join(source, file), join(target, file), constants.COPYFILE_EXCL);
copyFileSync(join(source, "README.md"), join(target, "PLAN.md"), constants.COPYFILE_EXCL);
console.log("TEMPORAL_SCOPE_STAGED: six leaves, G0-G15 pending; no approvals or checks executed");
