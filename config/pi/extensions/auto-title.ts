/**
 * Auto-title extension.
 *
 * Generates a session title by summarizing user prompts using a fast LLM.
 * Sets the session name and terminal title. On resume, restores the cached
 * title from session entries without re-calling the LLM.
 *
 * Fires asynchronously — doesn't block the agent loop.
 *
 * Title generation is attempted:
 * - On before_agent_start (after user submits a prompt)
 * - On session_start with reason "resume", "reload", or "fork"
 *   (if the session has user messages but no cached title yet)
 *
 * If a session has no title yet (e.g. extension was just added mid-session),
 * all user prompts up to the current point are used for summarization.
 *
 * Config: ~/.pi/agent/auto-title.json (or <cwd>/.pi/auto-title.json)
 * Project config overrides global config.
 *
 * Example config:
 * ```json
 * {
 *   "provider": "openrouter",
 *   "model": "google/gemini-3.5-flash",
 *   "prompt": "Given the user messages below from a session with an AI coding assistant, generate a very short title (at most 6 words, ideally 2-4) that captures the essence of what they're working on. Do not include quotes. Output only the title text, nothing else.\n\nUser messages:\n",
 *   "maxWords": 6,
 *   "maxInputLength": 2000
 * }
 * ```
 */

import { complete, getModel } from "@earendil-works/pi-ai";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

interface AutoTitleConfig {
	/** Provider name (e.g., "openrouter", "google") */
	provider: string;
	/** Model ID (e.g., "google/gemini-3.5-flash") */
	model: string;
	/** Custom prompt template (prepended to the concatenated user messages) */
	prompt: string;
	/** Max words in the generated title (included in default prompt) */
	maxWords: number;
	/** Max characters of concatenated user messages sent to the title model */
	maxInputLength: number;
}

const DEFAULT_CONFIG: AutoTitleConfig = {
	provider: "openrouter",
	model: "google/gemini-3.5-flash",
	prompt:
		"Given the user messages below from a session with an AI coding assistant, generate a very short title (at most 6 words, ideally 2-4) that captures the essence of what they're working on. Do not include quotes. Output only the title text, nothing else.\n\nUser messages:\n",
	maxWords: 6,
	maxInputLength: 2000,
};

function loadConfig(cwd: string): AutoTitleConfig {
	const globalPath = join(getAgentDir(), "auto-title.json");
	const projectPath = join(cwd, ".pi", "auto-title.json");

	let globalOverrides: Partial<AutoTitleConfig> = {};
	let projectOverrides: Partial<AutoTitleConfig> = {};

	if (existsSync(globalPath)) {
		try {
			globalOverrides = JSON.parse(readFileSync(globalPath, "utf-8"));
		} catch (err) {
			console.error(`auto-title: failed to load ${globalPath}: ${err}`);
		}
	}

	if (existsSync(projectPath)) {
		try {
			projectOverrides = JSON.parse(readFileSync(projectPath, "utf-8"));
		} catch (err) {
			console.error(`auto-title: failed to load ${projectPath}: ${err}`);
		}
	}

	return { ...DEFAULT_CONFIG, ...globalOverrides, ...projectOverrides };
}

/** Extract text from a message content (string or array of content blocks). */
const extractText = (content: unknown): string => {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.filter((b: { type?: string; text?: string }) => b.type === "text" && typeof b.text === "string")
		.map((b: { text: string }) => b.text)
		.join("\n");
};

/** Concatenate all user messages from the branch, numbered and truncated. */
const gatherUserTexts = (
	branch: Array<{ type: string; message?: { role?: string; content?: unknown } }>,
	maxLength: number,
): string => {
	const userTexts: string[] = [];
	for (const entry of branch) {
		if (entry.type === "message" && entry.message?.role === "user") {
			const text = extractText(entry.message.content).trim();
			if (text) userTexts.push(text);
		}
	}
	if (userTexts.length === 0) return "";

	const numbered = userTexts.map((t, i) => `[${i + 1}] ${t}`).join("\n\n");
	return numbered.length > maxLength ? numbered.slice(0, maxLength) + "…" : numbered;
};

/** Walk backwards to find the most recent auto-title entry. */
const restoreCachedTitle = (
	entries: Array<{ type: string; customType?: string; data?: unknown }>,
): string | undefined => {
	for (let i = entries.length - 1; i >= 0; i--) {
		const entry = entries[i];
		if (entry.type === "custom" && entry.customType === "auto-title" && entry.data) {
			const data = entry.data as { title: string };
			if (data.title) return data.title;
		}
	}
	return undefined;
};

/** Fire-and-forget title generation. Never blocks the agent. */
async function generateTitle(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	config: AutoTitleConfig,
	userText: string,
) {
	const model = getModel(config.provider, config.model);
	if (!model) return;

	const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
	if (!auth?.ok || !auth.apiKey) return;

	try {
		const response = await complete(
			model,
			{
				messages: [
					{
						role: "user",
						content: [{ type: "text", text: config.prompt + userText }],
						timestamp: Date.now(),
					},
				],
			},
			{
				apiKey: auth.apiKey,
				headers: auth.headers,
				reasoningEffort: model.reasoning ? "low" : undefined,
			},
		);

		const title = response.content
			.filter((c: { type: string }) => c.type === "text")
			.map((c: { text: string }) => c.text)
			.join("")
			.trim()
			.replace(/^["']|["']$/g, ""); // strip wrapping quotes

		if (title) {
			pi.setSessionName(title);
			ctx.ui.setTitle(`π — ${title}`);
			pi.appendEntry("auto-title", { title });
		}
	} catch (err) {
		console.error(`auto-title: generateTitle failed`, err);
	}
}

export default function (pi: ExtensionAPI) {
	let titled = false;
	let config: AutoTitleConfig = DEFAULT_CONFIG;

	pi.on("session_start", async (event, ctx) => {
		config = loadConfig(ctx.cwd);

		// Restore cached title from session entries (avoids re-calling the LLM)
		const cached = restoreCachedTitle(ctx.sessionManager.getEntries());
		if (cached) {
			titled = true;
			pi.setSessionName(cached);
			ctx.ui.setTitle(`π — ${cached}`);
			return;
		}

		// On resume/reload/fork, the session may already have user messages but no title
		// (e.g. extension was just added). Generate one from existing messages.
		if (event.reason === "resume" || event.reason === "reload" || event.reason === "fork") {
			titled = true;
			const userText = gatherUserTexts(ctx.sessionManager.getBranch(), config.maxInputLength);
			if (userText) {
				generateTitle(pi, ctx, config, userText);
			} else {
				titled = false;
			}
		} else {
			titled = false;
		}
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (titled) return;
		titled = true;

		// On first prompt, the user message isn't in sessionManager yet,
		// so use event.prompt directly. For later prompts, gather from the branch.
		const branch = ctx.sessionManager.getBranch();
		const userMsgs = branch.filter(
			(e: { type: string; message?: { role?: string } }) =>
				e.type === "message" && e.message?.role === "user",
		);

		let userText: string;
		if (userMsgs.length > 0) {
			userText = gatherUserTexts(branch, config.maxInputLength);
		} else if (event.prompt) {
			userText = event.prompt;
			if (userText.length > config.maxInputLength)
				userText = userText.slice(0, config.maxInputLength) + "…";
		} else {
			titled = false;
			return;
		}

		generateTitle(pi, ctx, config, userText);
	});

	pi.registerCommand("reset-title", {
		description: "Recalculate the session title",
		handler: async (_args, ctx) => {
			const userText = gatherUserTexts(ctx.sessionManager.getBranch(), config.maxInputLength);
			if (!userText) {
				ctx.ui.notify("No user messages to summarize", "warning");
				return;
			}
			ctx.ui.notify("Recalculating title…", "info");
			generateTitle(pi, ctx, config, userText);
		},
	});
};