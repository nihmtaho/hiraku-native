import { test } from "node:test";
import assert from "node:assert/strict";
import { main, merge, review } from "../delivery.mjs";

const sha = "b".repeat(40);
const ok = [
  { __typename: "CheckRun", name: "ci", conclusion: "SUCCESS" },
  { __typename: "StatusContext", context: "hiraku/review", state: "SUCCESS" },
];

// Fake gh: records calls, answers pr view and the files listing.
function fakeGh({ head = sha, base = "develop", state = "OPEN", isDraft = false, rollup = ok, files = ["App/Hiraku/X.swift"], mergeError } = {}) {
  const calls = [];
  const run = (args) => {
    calls.push(args);
    if (args[1] === "view") return JSON.stringify({ headRefOid: head, baseRefName: base, isDraft, state, statusCheckRollup: rollup });
    if (args[0] === "api" && args[1].endsWith("/files")) return files.join("\n");
    if (args[1] === "merge" && mergeError && args.includes("--auto")) throw Object.assign(new Error("x"), { stderr: mergeError });
    return "";
  };
  return { run, calls };
}

test("review posts a status bound to the reviewed head SHA", () => {
  const { run, calls } = fakeGh();
  review(run, 7, "PASS", sha);
  const post = calls.find((c) => c[1]?.includes("/statuses/"));
  assert.ok(post.includes(`repos/{owner}/{repo}/statuses/${sha}`));
  assert.ok(post.includes("state=success") && post.includes("context=hiraku/review"));
});

test("review refuses when head moved after the review", () => {
  assert.throws(() => review(fakeGh({ head: "c".repeat(40) }).run, 7, "PASS", sha), /Head đã đổi/);
});

test("merge enables squash auto-merge pinned to the SHA when review and ci passed", () => {
  const { run, calls } = fakeGh();
  merge(run, 7, sha);
  assert.deepEqual(calls.at(-1), ["pr", "merge", "7", "--squash", "--match-head-commit", sha, "--auto"]);
});

test("merge falls back to a direct squash only when auto-merge says clean status", () => {
  const { run, calls } = fakeGh({ mergeError: "Pull request is in clean status" });
  assert.match(merge(run, 7, sha), /merged squash/);
  assert.deepEqual(calls.at(-1), ["pr", "merge", "7", "--squash", "--match-head-commit", sha]);
  assert.throws(() => merge(fakeGh({ mergeError: "boom" }).run, 7, sha), /x/);
});

const blocked = [
  ["missing review", { rollup: [ok[0]] }, /hiraku\/review/],
  ["failed review", { rollup: [ok[0], { context: "hiraku/review", state: "FAILURE" }] }, /hiraku\/review/],
  ["missing ci", { rollup: [ok[1]] }, /"ci"/],
  ["failed ci re-run", { rollup: [...ok, { name: "ci", conclusion: "FAILURE" }] }, /"ci"/],
  ["wrong base", { base: "main" }, /Base/],
  ["draft", { isDraft: true }, /draft/],
  ["closed", { state: "MERGED" }, /không còn mở/],
  ["policy file", { files: ["AGENTS.md"] }, /policy/],
  ["workflow file", { files: [".github/workflows/ci.yml"] }, /policy/],
  ["delivery script", { files: [".agents/hiraku/delivery.mjs"] }, /policy/],
];
for (const [name, options, message] of blocked) {
  test(`merge is blocked: ${name}`, () => {
    const { run, calls } = fakeGh(options);
    assert.throws(() => merge(run, 7, sha), message);
    assert.ok(!calls.some((c) => c[1] === "merge"));
  });
}

test("task records do not count as policy changes", () => {
  assert.doesNotThrow(() => merge(fakeGh({ files: [".agents/tasks/m0-07.md", "CHANGELOG.md"] }).run, 7, sha));
});

test("main validates arguments before calling gh", () => {
  const never = () => assert.fail("gh must not run");
  for (const argv of [["merge"], ["merge", "x", "--sha", sha], ["merge", "7"], ["review", "7", "MAYBE", "--sha", sha], ["nuke", "7"]]) {
    assert.throws(() => main(argv, never), argv.join(" "));
  }
});
