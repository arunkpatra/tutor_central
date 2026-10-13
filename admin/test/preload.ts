import { mock } from "bun:test";

// `server-only` throws outside Next's server bundle; the unit tests render server components directly.
mock.module("server-only", () => ({}));
