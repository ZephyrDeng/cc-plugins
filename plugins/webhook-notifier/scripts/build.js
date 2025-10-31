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
  outfile: "dist/index.js",
  banner: {
    js: "#!/usr/bin/env node",
  },
  // Mark all Node.js built-in modules and problematic dependencies as external
  packages: "external", // Don't bundle node_modules
  minify: !watch,
  sourcemap: true,
  logLevel: "info",
};

async function runBuild() {
  try {
    // Ensure dist directory exists
    if (!existsSync("dist")) {
      await mkdir("dist", { recursive: true });
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
      await chmod("dist/index.js", 0o755);

      console.log("✅ Build complete!");
      console.log("📦 Output: dist/index.js");
    }
  } catch (error) {
    console.error("❌ Build failed:", error);
    process.exit(1);
  }
}

runBuild();
