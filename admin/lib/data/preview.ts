import frame from "../../preview/frame.json";
import type { Data } from "./types";

const notYet = (what: string) => (): never => {
  throw new Error(`the preview has no ${what} yet`);
};

/** Preview mode's `Data` (D96): the boards' figures from `preview/*.json`; writes change nothing. */
export const previewData: Data = {
  centres: notYet("centres"),
  centre: notYet("centre"),
  activity: notYet("activity"),
  centreJobs: notYet("centreJobs"),
  openRecord: notYet("openRecord"),
  record: notYet("record"),
  cost: notYet("cost"),
  calls: notYet("calls"),
  call: notYet("call"),
  jobs: notYet("jobs"),
  job: notYet("job"),
  errors: notYet("errors"),
  alerts: notYet("alerts"),
  audit: notYet("audit"),
  acknowledge: async () => true,
  retry: async () => true,
  cancel: async () => true,
  auditWrite: async () => {},
  adminEmail: async () => frame.email,
};
