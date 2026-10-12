import { existsSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { NodeCompiler } from "@myriaddreamin/typst-ts-node-compiler";

/** Where the committed fonts are (api/fonts, OFL): beside the function on Vercel (`includeFiles`), the package's root
 *  locally. */
export function fontsDir(): string {
  const candidates = [join(process.cwd(), "fonts"), fileURLToPath(new URL("../../fonts", import.meta.url)), join(process.cwd(), "api", "fonts")];
  const found = candidates.find((dir) => existsSync(join(dir, "NotoSans-Regular.ttf")));
  if (!found) throw new Error("the PDF fonts are not with the function");
  return found;
}

let compiler: NodeCompiler | undefined;

/** A Typst source rendered to a PDF with the committed fonts (D89): one compiler a process. Throws in words when the
 *  source does not compile (a fault of ours, never a tutor's). */
export async function renderPdf(source: string): Promise<{ bytes: Uint8Array; pages: number }> {
  compiler ??= NodeCompiler.create({ fontArgs: [{ fontPaths: [fontsDir()] }] });
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
