/** A marked mock's tallies by skill (Domain's GapTallies.bySkill, ported for the exam job, D106; held equal by
 *  tools/contract/gap-cases.json): each skill's marks across the mock's questions in the order the skills first appear;
 *  a question the marking missed counts nothing, a mark is held to its question's marks; the note is the first non-empty
 *  note on a question that lost marks. */
export type Tally = { skill: string; right: number; of: number; note?: string };

export function tallies(
  marking: { number: number; marks: number; note?: string | null }[],
  mock: { sections: { questions: { number: number; marks: number; skill: string }[] }[] },
): Tally[] {
  const marked = new Map<number, { marks: number; note?: string | null }>();
  for (const q of marking) if (!marked.has(q.number)) marked.set(q.number, q);
  const order: string[] = [];
  const right = new Map<string, number>();
  const of = new Map<string, number>();
  const notes = new Map<string, string>();
  for (const question of mock.sections.flatMap((s) => s.questions)) {
    if (!right.has(question.skill)) order.push(question.skill);
    const mark = marked.get(question.number);
    const got = Math.min(mark?.marks ?? 0, question.marks);
    right.set(question.skill, (right.get(question.skill) ?? 0) + got);
    of.set(question.skill, (of.get(question.skill) ?? 0) + question.marks);
    if (got < question.marks && !notes.has(question.skill) && mark?.note) notes.set(question.skill, mark.note);
  }
  return order.map((skill) => {
    const note = notes.get(skill);
    return { skill, right: right.get(skill) ?? 0, of: of.get(skill) ?? 0, ...(note ? { note } : {}) };
  });
}
