#!/usr/bin/env node
// The only path to the review verdict and merge: checks run here, GitHub rulesets enforce them again.
import { execFileSync } from "node:child_process";
import { pathToFileURL } from "node:url";
import { protectedPath } from "./guard.mjs";

export const REVIEW_CONTEXT = "hiraku/review";
export const CI_CONTEXT = "ci";
const BASE = "develop";
const SHA = /^[0-9a-f]{40}$/;

export const ghRun = (args) => execFileSync("gh", args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });

function pullRequest(run, pr) {
  const info = JSON.parse(run(["pr", "view", String(pr), "--json", "headRefOid,baseRefName,isDraft,state,statusCheckRollup"]));
  const files = run(["api", `repos/{owner}/{repo}/pulls/${pr}/files`, "--paginate", "--jq", ".[].filename"])
    .split("\n").filter(Boolean);
  return { ...info, files };
}

function assertReviewable(info, sha) {
  if (!SHA.test(sha)) throw new Error("Cần --sha là head SHA đầy đủ 40 ký tự.");
  if (info.state !== "OPEN") throw new Error(`PR không còn mở (${info.state}).`);
  if (info.baseRefName !== BASE) throw new Error(`Base phải là ${BASE}, không phải ${info.baseRefName}.`);
  if (info.headRefOid !== sha) throw new Error(`Head đã đổi (${info.headRefOid}); review và ship đúng SHA mới.`);
}

// Every entry of a context must pass: a re-run or duplicate that failed blocks.
function passed(rollup, context) {
  const entries = rollup.filter((x) => (x.name ?? x.context) === context);
  return entries.length > 0 && entries.every((x) => (x.conclusion ?? x.state) === "SUCCESS");
}

export function review(run, pr, verdict, sha) {
  assertReviewable(pullRequest(run, pr), sha);
  const state = verdict === "PASS" ? "success" : "failure";
  run(["api", `repos/{owner}/{repo}/statuses/${sha}`, "-f", `state=${state}`, "-f", `context=${REVIEW_CONTEXT}`,
    "-f", `description=Independent review ${verdict} for ${sha.slice(0, 7)}`]);
  return `${REVIEW_CONTEXT} ${state} @ ${sha}`;
}

export function merge(run, pr, sha) {
  const info = pullRequest(run, pr);
  assertReviewable(info, sha);
  if (info.isDraft) throw new Error("PR đang là draft.");
  const policy = info.files.filter((f) => !f.startsWith(".agents/tasks/") && protectedPath(f));
  if (policy.length) throw new Error(`PR chạm policy/checker, người vận hành merge: ${policy.join(", ")}`);
  if (!passed(info.statusCheckRollup, REVIEW_CONTEXT)) throw new Error(`Thiếu ${REVIEW_CONTEXT} PASS cho ${sha}.`);
  if (!passed(info.statusCheckRollup, CI_CONTEXT)) throw new Error(`Check bắt buộc "${CI_CONTEXT}" chưa đạt cho ${sha}.`);
  const args = ["pr", "merge", String(pr), "--squash", "--match-head-commit", sha];
  try {
    run([...args, "--auto"]);
    return `auto-merge squash enabled @ ${sha}`;
  } catch (error) {
    // GitHub refuses auto-merge when nothing is left to wait for; the ruleset still guards the direct merge.
    if (!/clean status/i.test(String(error.stderr ?? error.message))) throw error;
  }
  run(args);
  return `merged squash @ ${sha}`;
}

export function main(argv, run = ghRun) {
  const [command, pr, ...rest] = argv;
  const sha = rest.at(-2) === "--sha" ? rest.at(-1) : undefined;
  if (!/^\d+$/.test(pr ?? "")) throw new Error("Cần số PR.");
  if (command === "review" && rest.length === 3 && ["PASS", "FAIL"].includes(rest[0])) return review(run, pr, rest[0], sha);
  if (command === "merge" && rest.length === 2) return merge(run, pr, sha);
  throw new Error("Usage: delivery.mjs review <pr> <PASS|FAIL> --sha <sha> | merge <pr> --sha <sha>");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    process.stdout.write(`${main(process.argv.slice(2))}\n`);
  } catch (error) {
    process.stderr.write(`BLOCKED: ${error.message}\n`);
    process.exitCode = 1;
  }
}
