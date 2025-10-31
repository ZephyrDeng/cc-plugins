#!/usr/bin/env node
/**
 * Build script using esbuild
 * Creates a single bundled executable with shebang
 */
import { build } from "esbuild";
import { chmod, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";

const watch = process.argv.includes("--watch");

const buildOptions = {
  entryPoints: ["src/index.ts"],
  bundle: true,
  platform: "node",
  target: "node18",
  format: "cjs", // Use CommonJS for better compatibility
  outfile: "scripts/bin/index.js",
  banner: {
    js: "#!/usr/bin/env node",
  },
  // Only exclude packages with native/binary dependencies
  external: ['node-notifier'],
  minify: !watch,
  sourcemap: true,
  logLevel: "info",
};

async function runBuild() {
  try {
    // Ensure scripts/bin directory exists
    if (!existsSync("scripts/bin")) {
      await mkdir("scripts/bin", { recursive: true });
    }

    if (watch) {
      const ctx = await build({
        ...buildOptions,
        logLevel: "info",
      });
      await ctx.watch();
      console.log("👀 Watching for changes...");
    } else {
      await build(buildOptions);

      // Make executable
      await chmod("scripts/bin/index.js", 0o755);

      console.log("✅ Build complete!");
      console.log("📦 Output: scripts/bin/index.js");
    }
  } catch (error) {
    console.error("❌ Build failed:", error);
    process.exit(1);
  }
}

runBuild();
