import { assertShell, evaluatePermission } from "../../lib/guard.mjs";

export default {
  id: "hiraku.guard",
  async setup(ctx) {
    const root = ctx.location.directory;
    await ctx.permission.hook("evaluate", (event) =>
      evaluatePermission(root, event, ctx.storage));
    await ctx.shell.hook("create.before", (event) => {
      // Kiểm cả raw command để chặn toán tử shell sau khi scanner tách lệnh.
      assertShell(root, "hiraku-coder", event.command, event.cwd);
    });
    await ctx.storage.set("loaded", { version: ctx.app.version });
  },
};
