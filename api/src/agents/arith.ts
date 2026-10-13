/** A numeric key checked by computation (D99): the model writes a proof, an arithmetic expression over numbers alone
 *  and the value it equals, and the server evaluates it here, without `eval`. Numbers with decimals; `+ - * /`; `^`,
 *  right-associative and above unary minus (`-2^2` is -4); parentheses; `sqrt(x)`. Anything else throws. */
export class ArithError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ArithError";
  }
}

export function evaluate(expression: string): number {
  const tokens = tokenize(expression);
  let at = 0;
  const peek = () => tokens[at];
  const take = (want?: string) => {
    const token = tokens[at];
    if (token === undefined || (want !== undefined && token !== want)) throw new ArithError(`expected ${want ?? "more"} at ${at}`);
    at += 1;
    return token;
  };
  // sum := product (("+" | "-") product)*; product := unary (("*" | "/") unary)*; unary := "-" unary | power;
  // power := atom ("^" unary)?; atom := number | "(" sum ")" | "sqrt" "(" sum ")".
  const sum = (): number => {
    let value = product();
    while (peek() === "+" || peek() === "-") value = take() === "+" ? value + product() : value - product();
    return value;
  };
  const product = (): number => {
    let value = unary();
    while (peek() === "*" || peek() === "/") value = take() === "*" ? value * unary() : value / unary();
    return value;
  };
  const unary = (): number => {
    if (peek() === "-") {
      take();
      return -unary();
    }
    return power();
  };
  const power = (): number => {
    const base = atom();
    if (peek() !== "^") return base;
    take();
    return base ** unary();
  };
  const atom = (): number => {
    const token = take();
    if (token === "(") {
      const value = sum();
      take(")");
      return value;
    }
    if (token === "sqrt") {
      take("(");
      const value = sum();
      take(")");
      return Math.sqrt(value);
    }
    if (/^\d+(\.\d+)?$/.test(token)) return Number(token);
    throw new ArithError(`unexpected ${token}`);
  };
  const value = sum();
  if (at !== tokens.length) throw new ArithError(`unexpected ${tokens[at]}`);
  return value;
}

function tokenize(expression: string): string[] {
  const tokens: string[] = [];
  const pattern = /\s*(\d+(?:\.\d+)?|sqrt|[-+*/^()])/y;
  let index = 0;
  const text = expression.trimEnd();
  while (index < text.length) {
    pattern.lastIndex = index;
    const match = pattern.exec(text);
    if (!match?.[1]) throw new ArithError(`unexpected character at ${index}`);
    tokens.push(match[1]);
    index = pattern.lastIndex;
  }
  if (tokens.length === 0) throw new ArithError("empty");
  return tokens;
}

/** True when the expression evaluates to `equals` within a millionth of it (or of 1); false for anything that does not
 *  evaluate to a finite number. */
export function proofHolds(proof: { expression: string; equals: number }): boolean {
  try {
    const value = evaluate(proof.expression);
    return Number.isFinite(value) && Math.abs(value - proof.equals) <= 1e-6 * Math.max(1, Math.abs(proof.equals));
  } catch {
    return false;
  }
}
