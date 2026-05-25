import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Fireworks Session Affinity Plugin
 *
 * Injects an x-session-affinity header into requests made to the Fireworks
 * provider, using the pi session ID as the value. This ensures consistent
 * routing for multi-turn conversations with Fireworks AI models.
 *
 * Installation:
 *   Copy this file to ~/.pi/agent/extensions/fireworks-session-affinity.ts
 *   Or use: pi -e ./fireworks-session-affinity.ts
 *
 * The plugin will automatically inject the header for all Fireworks requests
 * when using pi's built-in Fireworks provider.
 */
export default function (pi: ExtensionAPI) {
  // Register the session affinity header when session starts
  pi.on("session_start", async (_event, ctx) => {
    // Get the session ID from the session manager
    const sessionId = ctx.sessionManager?.getSessionId?.();

    // Skip if we don't have a session ID (ephemeral mode)
    if (!sessionId) {
      return;
    }

    // Override the Fireworks provider with the session-specific header
    // When only headers is provided (no models), all existing models are preserved
    pi.registerProvider("fireworks", {
      headers: {
        "x-session-affinity": sessionId,
      },
    });
  });
}
