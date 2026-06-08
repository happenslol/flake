import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const CLI = resolve(__dirname, "node_modules/.bin/playwright-cli");

export default function (pi: ExtensionAPI) {
  pi.on("session_shutdown", async () => {
    await pi.exec("bash", ["-c", `${CLI} kill-all`], { timeout: 10_000 });
  });

  pi.registerTool({
    name: "browser",
    label: "Browser",
    description:
      "Control a browser via Playwright. Wraps the @playwright/cli — args are passed directly. " +
      "Common commands: open [url], close, goto <url>, click <target>, fill <target> <text>, " +
      "screenshot [target], snapshot [target], resize <w> <h>, eval <func> [target], " +
      "tab-list, tab-new [url], tab-close [index], tab-select <index>, " +
      "press <key>, go-back, go-forward, reload, type <text>, hover <target>, " +
      "drag <start> <end>, select <target> <val>, upload <file>, " +
      "check <target>, uncheck <target>, dialog-accept [prompt], dialog-dismiss, " +
      "delete-data, state-load <file>, state-save [file], " +
      "cookie-list, cookie-get <name>, cookie-set <name> <value>, cookie-delete <name>, " +
      "requests, request <index>, route <pattern>, unroute [pattern], " +
      "console [min-level], video-start [file], video-stop, " +
      "install, install-browser [browser], list, close-all, kill-all. " +
      "Use --json for JSON output, --raw for raw values. " +
      "Targets use Playwright selectors: text=Submit, [data-testid=foo], #id, .class, >> chain >> selectors.",
    promptSnippet: "Browse the web, take screenshots, interact with pages",
    promptGuidelines: [
      "Use browser to open web pages, interact with elements, take screenshots, and manage tabs.",
      "After taking a screenshot with browser, use show_image to display it at a chosen size.",
    ],
    parameters: Type.Object({
      command: Type.String({
        description: "Playwright CLI command and arguments, e.g. 'open https://example.com' or 'click text=Submit'",
      }),
    }),

    async execute(toolCallId, params, signal, _onUpdate, ctx) {
      const result = await pi.exec("bash", ["-c", `${CLI} ${params.command}`], {
        signal,
        timeout: 30_000,
        cwd: ctx.cwd,
      });

      const output = result.stdout || result.stderr || "(no output)";
      const isError = result.code !== 0;

      return {
        content: [{ type: "text", text: output.trim() }],
        details: { exitCode: result.code },
        ...(isError && { isError: true }),
      };
    },
  });
}
