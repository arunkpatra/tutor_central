/** The tutor's reminder choices on the account (`reminder_settings`, plan decision 6): the defaults when no row. */
export type ReminderSettings = {
  classOn: boolean;
  /** Minutes before the batch: 5, 10, 15, 30 or 60. */
  classMinutes: number;
  eventsOn: boolean;
  eventLead: "min15" | "min30" | "hour1" | "day_before";
  feesOn: boolean;
  /** The 1st to the 28th. */
  feesDay: number;
  planReadyOn: boolean;
  notesReadyOn: boolean;
};

export const DEFAULT_SETTINGS: ReminderSettings = {
  classOn: true,
  classMinutes: 60,
  eventsOn: true,
  eventLead: "hour1",
  feesOn: true,
  feesDay: 5,
  planReadyOn: true,
  notesReadyOn: true,
};

/** A row of `reminder_settings` as the app's settings. */
export function settingsOf(row: {
  class_on: boolean;
  class_minutes: number;
  events_on: boolean;
  event_lead: string;
  fees_on: boolean;
  fees_day: number;
  plan_ready_on: boolean;
  notes_ready_on: boolean;
} | null): ReminderSettings {
  if (!row) return DEFAULT_SETTINGS;
  return {
    classOn: row.class_on,
    classMinutes: row.class_minutes,
    eventsOn: row.events_on,
    eventLead: row.event_lead as ReminderSettings["eventLead"],
    feesOn: row.fees_on,
    feesDay: row.fees_day,
    planReadyOn: row.plan_ready_on,
    notesReadyOn: row.notes_ready_on,
  };
}
