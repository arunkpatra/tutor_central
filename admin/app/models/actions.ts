"use server";

import { notFound, redirect } from "next/navigation";
import { EFFORTS, knownModel, MODEL, STEPS } from "@/content/models";
import { requireAdmin } from "@/lib/admin";
import { data } from "@/lib/data";
import type { Effort, ModelChange, StepName } from "@/lib/data/types";
import { callerIp } from "@/lib/request";

const text = (form: FormData, name: string) => String(form.get(name) ?? "").trim();
const KIND = /^[a-z0-9_]{1,40}$/;

function kindOf(form: FormData): string {
  const kind = text(form, "kind");
  if (!KIND.test(kind)) notFound();
  return kind;
}

/** The kind's current draft: Switch off and on write it again with only the switch changed. */
async function draftOf(kind: string) {
  const model = await data().model(kind);
  const draft = model?.current.find((s) => s.step === "draft");
  if (!draft) notFound();
  return draft;
}

/** Save a step (D113): a new `ai_models` row from now. A model the API cannot price goes back with the field's words
 *  before anything is written; a blank note is none. The draft keeps its switch. */
export async function saveStep(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const kind = kindOf(form);
  const step = text(form, "step") as StepName;
  const effort = text(form, "effort") as Effort;
  if (!(STEPS as readonly string[]).includes(step) || !(EFFORTS as readonly string[]).includes(effort)) notFound();
  const model = text(form, "model");
  const fallback = text(form, "fallback");
  if (!knownModel(model) || (fallback !== "" && !knownModel(fallback))) redirect(`/models/${kind}?bad=model`);
  // Every step of a kind the table holds (a kind it never held is not found, not an error page).
  const draft = await draftOf(kind);
  const enabled = step === "draft" ? draft.enabled : true;
  const note = text(form, "note").slice(0, 400);
  const change: ModelChange = { kind, step, model, effort, fallback: fallback || null, enabled, note: note || null };
  await data().setModel(admin.userId, change, await callerIp());
  redirect(`/models/${kind}`);
}

/** Switch a kind off (D100): the draft written again disabled, with the reason as its note and the audit's. */
export async function switchOff(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const kind = kindOf(form);
  const reason = text(form, "reason").slice(0, 400);
  if (!reason) redirect(`/models/${kind}?off=1&empty=1`);
  const d = await draftOf(kind);
  const change: ModelChange = {
    kind,
    step: "draft",
    model: d.model,
    effort: d.effort,
    fallback: d.fallback_model,
    enabled: false,
    note: reason,
  };
  await data().setModel(admin.userId, change, await callerIp());
  redirect(`/models/${kind}`);
}

/** Switch a kind on: the draft written again enabled. */
export async function switchOn(form: FormData): Promise<void> {
  const admin = await requireAdmin();
  const kind = kindOf(form);
  const d = await draftOf(kind);
  const change: ModelChange = {
    kind,
    step: "draft",
    model: d.model,
    effort: d.effort,
    fallback: d.fallback_model,
    enabled: true,
    note: MODEL.switchedOn,
  };
  await data().setModel(admin.userId, change, await callerIp());
  redirect(`/models/${kind}`);
}
