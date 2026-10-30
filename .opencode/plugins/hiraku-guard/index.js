import { assertShell, assertShellBaseline, evaluatePermission } from "../../../.agents/hiraku/guard.mjs";

export default {
  id: "hiraku.guard",
  async setup(ctx) {
    const root = ctx.location.directory;
    await ctx.permission.hook("evaluate", (event) =>
      evaluatePermission(root, event, ctx.storage));
    await ctx.shell.hook("create.before", (event) => {
      // Raw command re-check catches delivery commands hidden behind shell operators.
      if (event.agent) return assertShell(root, event.agent, event.command, event.cwd);
      assertShellBaseline(root, event.command, event.cwd);
    });
    await ctx.storage.set("loaded", { version: ctx.app.version });
  },
};
