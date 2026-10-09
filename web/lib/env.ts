/** The App Store page, once the app is there (D47): a Vercel environment variable read at build. Unset, Home shows the
 *  email call to action. */
export function appStoreURL(): string | null {
  const url = process.env.APP_STORE_URL?.trim();
  return url ? url : null;
}

/** The commit this export was built from (`TC_COMMIT` from deploy-web.yml); "local" on a machine. The smoke reads it. */
export function commit(): string {
  return process.env.TC_COMMIT?.trim() || "local";
}
