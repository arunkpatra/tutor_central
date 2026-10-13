import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { NodeCompiler } from "@myriaddreamin/typst-ts-node-compiler";
import { log } from "../log.js";

/** Where the committed fonts are (api/fonts, OFL): beside the function on Vercel (`includeFiles`), the package's root
 *  locally. */
export function fontsDir(): string {
  const candidates = [join(process.cwd(), "fonts"), fileURLToPath(new URL("../../fonts", import.meta.url)), join(process.cwd(), "api", "fonts")];
  const found = candidates.find((dir) => existsSync(join(dir, "NotoSans-Regular.ttf")));
  if (!found) throw new Error("the PDF fonts are not with the function");
  return found;
}

/** The function's Typst workspace: the directory holding `fonts/` and `typst/` (mitex, D102). */
export function workspaceDir(): string {
  return dirname(fontsDir());
}

let compiler: NodeCompiler | undefined;

/** A formula written back as its words: `#mi("…");` and `#mitex("…");` become `#"…";`. */
export function withoutMaths(source: string): string {
  return source.replace(/#(?:mi|mitex)\(("(?:[^"\\]|\\.)*")\);/g, "#$1;");
}

/** A Typst source rendered to a PDF with the committed fonts (D89) and mitex (D102): one compiler a process. A source
 *  whose formula Typst cannot draw is rendered again with its formulae as words, logged: a model's slip never loses the
 *  page. Throws in words when the source does not compile (a fault of ours, never a tutor's). */
export async function renderPdf(source: string): Promise<{ bytes: Uint8Array; pages: number }> {
  try {
    return compile(source);
  } catch (e) {
    const plain = withoutMaths(source);
    if (plain === source) throw e;
    log.error({ at: "pdf", reason: "maths did not compile; drawn as words", error: e instanceof Error ? e : String(e) });
    return compile(plain);
  }
}

function compile(source: string): { bytes: Uint8Array; pages: number } {
  compiler ??= NodeCompiler.create({ workspace: workspaceDir(), fontArgs: [{ fontPaths: [fontsDir()] }] });
  const compiled = compiler.compile({ mainFileContent: source });
  const doc = compiled.result;
  if (!doc || compiled.hasError()) {
    const error = compiled.takeError();
    const words = error ? JSON.stringify(error.shortDiagnostics).slice(0, 400) : "no document";
    throw new Error(`the PDF did not compile: ${words}`);
  }
  const pages = doc.numOfPages;
  const bytes = new Uint8Array(compiler.pdf(doc));
  compiler.evictCache(10);
  return { bytes, pages };
}
