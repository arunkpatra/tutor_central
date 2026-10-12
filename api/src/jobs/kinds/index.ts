import type { JobHandler, JobKind } from "../types.js";
import { type PlanRecordSource, planJob } from "./plan.js";
import { sweep } from "./sweep.js";

/** The kinds the worker runs. A job of a kind not here fails at once, without a retry. */
export function makeHandlers(record?: PlanRecordSource): Partial<Record<JobKind, JobHandler>> {
  return record ? { sweep, plan: planJob(record) } : { sweep };
}
