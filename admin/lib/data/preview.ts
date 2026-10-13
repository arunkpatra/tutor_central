import centre from "../../preview/centre.json";
import centres from "../../preview/centres.json";
import frame from "../../preview/frame.json";
import record from "../../preview/record.json";
import type { Activity, Centre, Centres, Data, JobRow, Record } from "./types";

/** The preview's one centre is `preview`; any other id is gone. */
const PREVIEW_ID = "preview";

const notYet = (what: string) => (): never => {
  throw new Error(`the preview has no ${what} yet`);
};

/** Preview mode's `Data` (D96): the boards' figures from `preview/*.json`; writes change nothing. */
export const previewData: Data = {
  centres: async () => centres as Centres,
  centre: async (id) => (id === PREVIEW_ID ? (centre.centre as Centre) : null),
  activity: async (id) => (id === PREVIEW_ID ? (centre.activity as Activity[]) : []),
  centreJobs: async (id) => (id === PREVIEW_ID ? (centre.jobs as JobRow[]) : []),
  openRecord: async (_admin, id) => (id === PREVIEW_ID ? (record as Record) : null),
  record: async () => record as Record,
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
