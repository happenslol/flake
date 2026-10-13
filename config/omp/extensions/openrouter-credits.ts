/**
 * OpenRouter Credits Status
 *
 * Shows remaining OpenRouter credits in the status bar.
 * Fetches from https://openrouter.ai/api/v1/credits using OPENROUTER_API_KEY.
 * Refreshes every 60 seconds.
 */

import { theme } from "@oh-my-pi/pi-coding-agent";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

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

export default function (pi: ExtensionAPI) {
	async function refreshCredits(ctx: { ui: { setStatus: (id: string, s: string) => void } }) {
		const credits = await fetchCredits();
		if (credits === null) return;
		// Color: green if > $1, yellow if > $0.10, red otherwise
		const color = credits > 1 ? "success" : credits > 0.1 ? "warning" : "error";
		const label = credits < 1 ? credits.toFixed(4) : credits.toFixed(2);
		ctx.ui.setStatus("openrouter-credits", theme.fg(color, `OR $${label}`));
	}

	pi.on("session_start", async (_event, ctx) => {
		// Initial fetch
		await refreshCredits(ctx);

		// Refresh every 60s. Managed timer: errors are contained and it is
		// cleared automatically on session_shutdown.
		ctx.setInterval(() => refreshCredits(ctx), 60_000);
	});
}
