import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { readFileSync, statSync } from "node:fs";
import { resolve, extname } from "node:path";
import { Text } from "@earendil-works/pi-tui";

function readImageDimensions(data: Buffer): { width: number; height: number } | null {
  // PNG: width/height at bytes 16-23
  if (data[0] === 0x89 && data[1] === 0x50 && data[2] === 0x4e && data[3] === 0x47) {
    return {
      width: data.readUInt32BE(16),
      height: data.readUInt32BE(20),
    };
  }
  // JPEG: find SOF0/SOF2 marker
  if (data[0] === 0xff && data[1] === 0xd8) {
    let offset = 2;
    while (offset < data.length - 1) {
      if (data[offset] !== 0xff) break;
      const marker = data[offset + 1];
      if (marker === 0xc0 || marker === 0xc2) {
        return {
          height: data.readUInt16BE(offset + 5),
          width: data.readUInt16BE(offset + 7),
        };
      }
      if (marker >= 0xd0 && marker <= 0xd9) {
        offset += 2;
      } else {
        const segLen = data.readUInt16BE(offset + 2);
        offset += 2 + segLen;
      }
    }
  }
  // GIF: width/height at bytes 6-9 (little-endian)
  if (data[0] === 0x47 && data[1] === 0x49 && data[2] === 0x46) {
    return {
      width: data.readUInt16LE(6),
      height: data.readUInt16LE(8),
    };
  }
  // WebP: RIFF container
  if (
    data[0] === 0x52 && data[1] === 0x49 && data[2] === 0x46 && data[3] === 0x46 &&
    data[8] === 0x57 && data[9] === 0x45 && data[10] === 0x42 && data[11] === 0x50
  ) {
    if (data[12] === 0x56 && data[13] === 0x50 && data[14] === 0x38 && data[15] === 0x20) {
      const bits = data.readUInt32LE(26);
      return { width: bits & 0x3fff, height: (bits >> 16) & 0x3fff };
    }
    if (data[12] === 0x56 && data[13] === 0x50 && data[14] === 0x38 && data[15] === 0x4c) {
      const bits = data.readUInt32LE(25);
      return { width: (bits & 0x3fff) + 1, height: ((bits >> 14) & 0x3fff) + 1 };
    }
  }
  return null;
}

const MIME_TYPES: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".webp": "image/webp",
  ".bmp": "image/bmp",
  ".svg": "image/svg+xml",
};

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "show_image",
    label: "Show Image",
    description:
      "Display an image file inline in the terminal at a chosen size using the Kitty graphics protocol (works in Kitty, Ghostty, WezTerm, iTerm2). Specify the file path and desired display width/height in terminal cells.",
    promptSnippet: "Display images inline in the terminal at a chosen size",
    promptGuidelines: [
      "Use show_image when you want to display an image file in the terminal at a specific size, instead of relying on the default small preview.",
    ],
    parameters: Type.Object({
      path: Type.String({ description: "Path to the image file to display" }),
      width: Type.Optional(
        Type.Number({
          description:
            "Maximum width in terminal columns (cells). Defaults to the terminal width.",
        })
      ),
      height: Type.Optional(
        Type.Number({
          description:
            "Maximum height in terminal rows (cells). If omitted, computed from aspect ratio. Defaults to 40.",
        })
      ),
    }),

    async execute(toolCallId, params, signal, _onUpdate, ctx) {
      const absolutePath = resolve(ctx.cwd, params.path);

      let stat;
      try {
        stat = statSync(absolutePath);
      } catch {
        throw new Error(`File not found: ${absolutePath}`);
      }

      if (!stat.isFile()) {
        throw new Error(`Not a regular file: ${absolutePath}`);
      }

      const ext = extname(absolutePath).toLowerCase();
      const mimeType = MIME_TYPES[ext];
      if (!mimeType) {
        throw new Error(
          `Unsupported image format: ${ext}. Supported: ${Object.keys(MIME_TYPES).join(", ")}`
        );
      }

      const data = readFileSync(absolutePath);
      const base64 = data.toString("base64");
      const dimensions = readImageDimensions(data);

      const imgW = dimensions?.width ?? "?";
      const imgH = dimensions?.height ?? "?";
      const sizeKB = (stat.size / 1024).toFixed(1);
      const filename = absolutePath.split("/").pop() ?? absolutePath;

      // Return image in the content array (type: "image") so that pi's
      // ToolExecutionComponent handles rendering — including PNG conversion
      // for Kitty. Same approach as the built-in read tool.
      return {
        content: [
          {
            type: "text",
            text: `Displayed ${filename} (${mimeType}, ${imgW}×${imgH}, ${sizeKB}KB)`,
          },
          {
            type: "image",
            data: base64,
            mimeType,
          },
        ],
      };
    },

    renderResult(result, _options, theme, _context) {
      const content = result.content ?? [];
      const textBlock = content.find((c: any) => c.type === "text");
      if (textBlock) {
        return new Text(theme.fg("muted", textBlock.text), 0, 0);
      }
      return new Text("", 0, 0);
    },
  });
}