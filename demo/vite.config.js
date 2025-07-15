import { defineConfig } from "vite";
import { nodePolyfills } from "vite-plugin-node-polyfills";
import gleam from "vite-gleam";

export default defineConfig({
  plugins: [gleam(), nodePolyfills()],
});
