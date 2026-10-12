import type { JobHandler, JobKind } from "../types.js";
import { sweep } from "./sweep.js";

/** The kinds the worker runs. A job of a kind not here fails at once, without a retry. */
export const handlers: Partial<Record<JobKind, JobHandler>> = { sweep };
