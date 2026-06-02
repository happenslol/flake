/**
 * OpenRouter Credits Status
 *
 * Shows remaining OpenRouter credits in the status bar.
 * Fetches from https://openrouter.ai/api/v1/credits using OPENROUTER_API_KEY.
 * Refreshes every 60 seconds.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface OpenRouterCreditsResponse {
	data: {
		total_credits: number;
		total_usage: number;
	};
}

async function fetchCredits(): Promise<number | null> {
	const apiKey = process.env.OPENROUTER_API_KEY;
	if (!apiKey) return null;

	try {
		const response = await fetch("https://openrouter.ai/api/v1/credits", {
			headers: {
				Authorization: `Bearer ${apiKey}`,
			},
			signal: AbortSignal.timeout(5000),
		});

		if (!response.ok) return null;

		const json = (await response.json()) as OpenRouterCreditsResponse;
		const remaining = json.data?.total_credits - json.data?.total_usage;
		return isFinite(remaining) ? remaining : null;
	} catch {
		return null;
	}
}

function formatCredits(credits: number, theme: { fg: (c: string, s: string) => string }): string {
	// Color: green if > $1, yellow if > $0.10, red otherwise
	const color = credits > 1 ? "success" : credits > 0.1 ? "warning" : "error";
	const label = credits < 1 ? credits.toFixed(4) : credits.toFixed(2);
	return theme.fg(color, `OR $${label}`);
}

export default function (pi: ExtensionAPI) {
	let intervalId: ReturnType<typeof setInterval> | null = null;

	async function refreshCredits(ctx: { ui: { setStatus: (id: string, s: string | undefined) => void; theme: { fg: (c: string, s: string) => string } } }) {
		const credits = await fetchCredits();
		if (credits !== null) {
			const label = formatCredits(credits, ctx.ui.theme);
			ctx.ui.setStatus("openrouter-credits", label);
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		// Initial fetch
		await refreshCredits(ctx);

		// Refresh every 60s
		if (intervalId) clearInterval(intervalId);
		intervalId = setInterval(() => refreshCredits(ctx), 60_000);
	});

	pi.on("session_shutdown", () => {
		if (intervalId) {
			clearInterval(intervalId);
			intervalId = null;
		}
	});
}