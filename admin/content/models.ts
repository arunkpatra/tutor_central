/** A model's id as the boards write it: "claude-sonnet-5-5" is "Sonnet 5.5", its family "Sonnet". */
const ID = /^claude-([a-z]+)-(\d+)-(\d+)$/;

export function family(model: string | null): string {
  const m = model?.match(ID);
  return m?.[1] ? m[1].charAt(0).toUpperCase() + m[1].slice(1) : (model ?? "—");
}

export function modelName(model: string | null): string {
  const m = model?.match(ID);
  return m ? `${family(model)} ${m[2]}.${m[3]}` : (model ?? "—");
}
