import type { NextConfig } from "next";

/** The admin portal (D78, D94): server-rendered pages behind the gate, deployed only by deploy-admin.yml. */
const config: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
};

export default config;
