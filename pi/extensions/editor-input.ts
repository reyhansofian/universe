import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawnSync } from "child_process";
import { writeFileSync, readFileSync, unlinkSync, existsSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";

// Open $EDITOR to compose input. Trigger by typing /vim.
// Content is placed in the input field for manual review before submitting.
export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, ctx) => {
    if (event.source === "extension") return { action: "continue" };

    const text = event.text?.trim() ?? "";
    if (text !== "/vim") return { action: "continue" };

    const editor = "nvim";
    const tmpFile = join(tmpdir(), `pi-input-${Date.now()}.md`);

    try {
      writeFileSync(tmpFile, "", "utf-8");

      const result = spawnSync(editor, [tmpFile], {
        stdio: "inherit",
        env: process.env,
      });

      if (result.status !== 0) {
        ctx.ui.notify("Editor exited with non-zero status", "warning");
        return { action: "handled" };
      }

      if (!existsSync(tmpFile)) {
        ctx.ui.notify("Temp file not found", "warning");
        return { action: "handled" };
      }

      const content = readFileSync(tmpFile, "utf-8").trim();

      if (!content) {
        ctx.ui.notify("Empty input, skipped", "info");
        return { action: "handled" };
      }

      ctx.ui.setEditorText(content);
      return { action: "handled" };
    } finally {
      try {
        if (existsSync(tmpFile)) unlinkSync(tmpFile);
      } catch {}
    }
  });
}
