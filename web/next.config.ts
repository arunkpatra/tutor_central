import type { NextConfig } from "next";

/** Five static pages (D44): the export is served by Vercel as files; nothing runs on a server. */
const config: NextConfig = {
  output: "export",
  reactStrictMode: true,
  poweredByHeader: false,
};

export default config;
