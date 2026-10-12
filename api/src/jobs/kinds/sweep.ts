import type { JobHandler } from "../types.js";

/** The platform's hourly sweep (plan decision 28): rows left pending past ten minutes (a function killed between the call
 *  and the finish) are closed as failed, so they stop counting and their key becomes a new call. Phase 18 adds photos. */
export const sweep: JobHandler = {
  async step(_job, ctx) {
    const closed = await ctx.jobs.closePending();
    return { kind: "done", name: "pending", result: { closed } };
  },
};
