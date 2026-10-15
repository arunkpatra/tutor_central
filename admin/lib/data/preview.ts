import alerts from "../../preview/alerts.json";
import audit from "../../preview/audit.json";
import call from "../../preview/call.json";
import callFeedback from "../../preview/call-feedback.json";
import callReduced from "../../preview/call-reduced.json";
import calls from "../../preview/calls.json";
import centre from "../../preview/centre.json";
import centres from "../../preview/centres.json";
import cost from "../../preview/cost.json";
import errors from "../../preview/errors.json";
import evals from "../../preview/evals.json";
import figures from "../../preview/figures.json";
import frame from "../../preview/frame.json";
import job from "../../preview/job.json";
import jobs from "../../preview/jobs.json";
import model from "../../preview/model.json";
import models from "../../preview/models.json";
import record from "../../preview/record.json";
import syllabi from "../../preview/syllabi.json";
import syllabus from "../../preview/syllabus.json";
import type {
  Activity,
  Alerts,
  AuditRow,
  Call,
  Calls,
  Centre,
  Centres,
  Cost,
  Data,
  Errors,
  EvalRuns,
  Job,
  JobRow,
  Jobs,
  Model,
  Models,
  Record,
  ReportLast,
  Syllabi,
  Syllabus,
  Week,
} from "./types";

/** The preview's one centre is `preview`; any other id is gone. */
const PREVIEW_ID = "preview";

/** Preview mode's `Data` (D96): the boards' figures from `preview/*.json`; writes change nothing. */
export const previewData: Data = {
  centres: async () => centres as Centres,
  centre: async (id) => (id === PREVIEW_ID ? (centre.centre as Centre) : null),
  activity: async (id) => (id === PREVIEW_ID ? (centre.activity as Activity[]) : []),
  centreJobs: async (id) => (id === PREVIEW_ID ? (centre.jobs as JobRow[]) : []),
  openRecord: async (_admin, id) => (id === PREVIEW_ID ? (record as Record) : null),
  record: async () => record as Record,
  cost: async () => cost as Cost,
  calls: async () => calls as Calls,
  call: async (id) =>
    id === PREVIEW_ID
      ? (call as Call)
      : id === callFeedback.id
        ? (callFeedback as unknown as Call)
        : id === callReduced.id
          ? (callReduced as unknown as Call)
          : null,
  jobs: async () => jobs as Jobs,
  job: async (id) => (id === job.id ? (job as Job) : null),
  errors: async () => errors as Errors,
  alerts: async () => alerts as Alerts,
  audit: async () => audit as AuditRow[],
  acknowledge: async () => true,
  retry: async () => true,
  cancel: async () => true,
  auditWrite: async () => {},
  adminEmail: async () => frame.email,
  models: async () => models as Models,
  // The preview's one kind is `preview` (the board's brief), and the brief by its own name.
  model: async (kind) => (kind === PREVIEW_ID || kind === model.kind ? (model as Model) : null),
  setModel: async () => "preview",
  setAllowance: async (_admin, centre) => centre === PREVIEW_ID,
  setLines: async () => {},
  figures: async (weeks) => (figures.weeks as Week[]).slice(0, weeks),
  reasons: async () => figures.reasons,
  reportLast: async () => figures.report as ReportLast,
  sendReport: async () => "preview-report",
  evalRuns: async () => evals as EvalRuns,
  runEvals: async () => "preview-done",
  syllabi: async () => syllabi as Syllabi,
  syllabus: async (id) => (id === PREVIEW_ID ? (syllabus as Syllabus) : null),
};
