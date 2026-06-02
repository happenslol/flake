/**
 * Firecrawl Extension
 *
 * Provides web search and page fetching tools using the Firecrawl API.
 * Requires FIRECRAWL_API_KEY environment variable.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { keyHint } from "@earendil-works/pi-coding-agent";
import { Text, truncateToWidth } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const FIRECRAWL_BASE = "https://api.firecrawl.dev/v2";

interface SearchDetails {
  query: string;
  resultCount: number;
  results?: Array<{ title?: string; url?: string; description?: string }>;
  error?: boolean;
  status?: number;
}

interface FetchDetails {
  url: string;
  title?: string;
  formats?: string[];
  contentLength?: number;
  error?: boolean;
  status?: number;
}

function getApiKey(): string {
  const key = process.env.FIRECRAWL_API_KEY;
  if (!key) {
    throw new Error("FIRECRAWL_API_KEY environment variable is not set");
  }
  return key;
}

export default function firecrawlExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web using Firecrawl. Returns a list of results with titles, URLs, and descriptions. Use this when you need to find information on the web.",
    promptSnippet: "Search the web for information",
    promptGuidelines: [
      "Use web_search when you need to find current information on the internet that you don't already know.",
      "Prefer web_search over guessing URLs or facts you're unsure about.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
      limit: Type.Optional(
        Type.Number({ description: "Maximum number of results (default 5, max 10)", default: 5 }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const limit = Math.min(params.limit ?? 5, 10);
      const response = await fetch(`${FIRECRAWL_BASE}/search`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${getApiKey()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ query: params.query, limit }),
        signal,
      });

      if (!response.ok) {
        const text = await response.text();
        return {
          content: [
            {
              type: "text",
              text: `Search failed (${response.status}): ${text}`,
            },
          ],
          details: { query: params.query, resultCount: 0, error: true, status: response.status } as SearchDetails,
          isError: true,
        };
      }

      const data = (await response.json()) as {
        data?: {
          web?: Array<{
            title?: string;
            url?: string;
            description?: string;
          }>;
        };
      };

      const results = data.data?.web ?? [];
      if (results.length === 0) {
        return {
          content: [{ type: "text", text: "No results found." }],
          details: { query: params.query, resultCount: 0 } as SearchDetails,
        };
      }

      const formatted = results
        .map((r, i) => {
          const parts: string[] = [];
          if (r.title) parts.push(`### ${i + 1}. ${r.title}`);
          if (r.url) parts.push(`URL: ${r.url}`);
          if (r.description) parts.push(r.description);
          return parts.join("\n");
        })
        .join("\n\n---\n\n");

      return {
        content: [{ type: "text", text: formatted }],
        details: {
          query: params.query,
          resultCount: results.length,
          results,
        } as SearchDetails,
      };
    },

    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("web_search ")) + theme.fg("accent", `"${args.query}"`),
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme) {
      const details = result.details as SearchDetails | undefined;
      if (!details) {
        const text = result.content[0];
        return new Text(text?.type === "text" ? text.text : "", 0, 0);
      }

      if (details.error) {
        return new Text(theme.fg("error", `Search failed (${details.status})`), 0, 0);
      }

      if (details.resultCount === 0) {
        return new Text(theme.fg("dim", "No results found"), 0, 0);
      }

      if (!expanded) {
        return new Text(
          theme.fg("success", "✓ ") +
            theme.fg("muted", `${details.resultCount} result${details.resultCount === 1 ? "" : "s"}`) +
            theme.fg("dim", ` (${keyHint("app.tools.expand", "expand")})`),
          0,
          0,
        );
      }

      const lines: string[] = [];
      for (const r of details.results ?? []) {
        let line = theme.fg("success", "• ");
        if (r.title) line += theme.fg("text", r.title);
        if (r.url) line += theme.fg("dim", ` — ${r.url}`);
        if (r.description) line += "\n  " + theme.fg("dim", r.description);
        lines.push(line);
      }
      return new Text(lines.join("\n"), 0, 0);
    },
  });

  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description:
      "Fetch and extract content from a web page URL using Firecrawl. Returns the page content as markdown and/or HTML. Use this to read the content of a specific URL.",
    promptSnippet: "Fetch and read the content of a web page",
    promptGuidelines: [
      "Use web_fetch when you have a specific URL and need to read its full content.",
      "Use web_search first if you need to find relevant URLs, then web_fetch to read them.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "URL to fetch" }),
      formats: Type.Optional(
        Type.Array(Type.String({ description: "Output formats: markdown, html" }), {
          description: "Formats to extract (default: [markdown])",
          default: ["markdown"],
        }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const formats = params.formats?.length ? params.formats : ["markdown"];
      const response = await fetch(`${FIRECRAWL_BASE}/scrape`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${getApiKey()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ url: params.url, formats }),
        signal,
      });

      if (!response.ok) {
        const text = await response.text();
        return {
          content: [
            {
              type: "text",
              text: `Fetch failed (${response.status}): ${text}`,
            },
          ],
          details: {
            url: params.url,
            error: true,
            status: response.status,
          } as FetchDetails,
          isError: true,
        };
      }

      const data = (await response.json()) as {
        data?: {
          markdown?: string;
          html?: string;
          metadata?: {
            title?: string;
            description?: string;
            language?: string;
          };
        };
      };

      const pageData = data.data;
      if (!pageData) {
        return {
          content: [{ type: "text", text: "No content returned from the page." }],
          details: { url: params.url } as FetchDetails,
        };
      }

      const parts: string[] = [];
      if (pageData.metadata?.title) {
        parts.push(`# ${pageData.metadata.title}`);
      }
      if (pageData.metadata?.description) {
        parts.push(`> ${pageData.metadata.description}\n`);
      }
      if (pageData.markdown) {
        parts.push(pageData.markdown);
      }
      if (pageData.html && formats.includes("html")) {
        parts.push(`\n---\n\n## HTML\n\n${pageData.html}`);
      }

      const contentText = parts.join("\n\n") || "No content extracted.";

      return {
        content: [{ type: "text", text: contentText }],
        details: {
          url: params.url,
          title: pageData.metadata?.title,
          formats,
          contentLength: contentText.length,
        } as FetchDetails,
      };
    },

    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("web_fetch ")) + theme.fg("accent", args.url),
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme) {
      const details = result.details as FetchDetails | undefined;
      if (!details) {
        const text = result.content[0];
        return new Text(text?.type === "text" ? text.text : "", 0, 0);
      }

      if (details.error) {
        return new Text(theme.fg("error", `Fetch failed (${details.status})`), 0, 0);
      }

      if (!expanded) {
        const title = details.title ? theme.fg("text", details.title) + " " : "";
        const size = details.contentLength
          ? `(${(details.contentLength / 1024).toFixed(1)}KB)`
          : "";
        return new Text(
          theme.fg("success", "✓ ") +
            title +
            theme.fg("dim", size) +
            theme.fg("dim", ` (${keyHint("app.tools.expand", "expand")})`),
          0,
          0,
        );
      }

      // When expanded, show the full content rendered from the result
      const text = result.content[0];
      const content = text?.type === "text" ? text.text : "";
      return new Text(theme.fg("muted", content), 0, 0);
    },
  });
}
