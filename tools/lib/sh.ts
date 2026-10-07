export type ShResult = { code: number; stdout: string; stderr: string };
export type ShOptions = { cwd?: string; env?: Record<string, string>; inherit?: boolean; stdin?: string };

/** Run a command and wait for it. A program that cannot be found answers 127, like a shell, instead of throwing. */
export async function sh(cmd: string[], opts: ShOptions = {}): Promise<ShResult> {
  let proc: ReturnType<typeof Bun.spawn>;
  try {
    proc = Bun.spawn(cmd, {
      cwd: opts.cwd,
      env: { ...process.env, ...opts.env },
      stdin: opts.stdin === undefined ? "ignore" : new Blob([opts.stdin]),
      stdout: opts.inherit ? "inherit" : "pipe",
      stderr: opts.inherit ? "inherit" : "pipe",
    });
  } catch (e) {
    return { code: 127, stdout: "", stderr: `${cmd[0]}: ${(e as Error).message}` };
  }
  const [stdout, stderr] = await Promise.all([
    opts.inherit ? "" : new Response(proc.stdout as ReadableStream).text(),
    opts.inherit ? "" : new Response(proc.stderr as ReadableStream).text(),
  ]);
  const code = await proc.exited;
  return { code, stdout, stderr };
}

/** Like sh, but a non-zero exit throws with the command and its stderr. Returns stdout. */
export async function must(cmd: string[], opts?: ShOptions): Promise<string> {
  const r = await sh(cmd, opts);
  if (r.code !== 0) throw new Error(`${cmd.join(" ")} failed (${r.code})\n${r.stderr}`);
  return r.stdout;
}
