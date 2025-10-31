/**
 * CLI Config Command
 * 配置管理
 */
import { existsSync, readFileSync, writeFileSync, copyFileSync } from "node:fs";
import { join } from "node:path";
import { stringify } from "yaml";
import { ConfigManager } from "../core/config.js";
import { DEFAULT_CONFIG } from "../types/config.js";

export async function configCommand(options: {
  show?: boolean;
  init?: boolean;
  validate?: boolean;
}): Promise<void> {
  try {
    if (options.init) {
      await initConfig();
    } else if (options.show) {
      await showConfig();
    } else if (options.validate) {
      await validateConfig();
    } else {
      console.log("Please specify an option: --show, --init, or --validate");
      console.log("Example: webhook config --show");
    }
  } catch (error) {
    console.error("❌ Config command failed:", error);
    process.exit(1);
  }
}

async function initConfig(): Promise<void> {
  const configPath = join(process.cwd(), ".webhookrc.yaml");

  if (existsSync(configPath)) {
    console.error(`❌ Config file already exists: ${configPath}`);
    console.log("💡 Use --show to view current config");
    process.exit(1);
  }

  // 生成默认配置文件
  const yamlContent = stringify(DEFAULT_CONFIG);
  writeFileSync(configPath, yamlContent, "utf-8");

  console.log("✅ Configuration file created successfully!");
  console.log(`📁 Location: ${configPath}`);
  console.log("\n💡 Edit this file to customize your notification settings");
}

async function showConfig(): Promise<void> {
  const config = new ConfigManager();
  const configPath = config.getConfigPath();

  if (!configPath) {
    console.log("⚠️  Using default configuration (no config file found)");
    console.log("\n💡 Run 'webhook config --init' to create a config file\n");
  } else {
    console.log(`📁 Config file: ${configPath}\n`);
  }

  console.log("📋 Current configuration:");
  console.log("─".repeat(60));

  const fullConfig = config.getConfig();

  // 格式化显示配置
  console.log("\n🔧 Logging:");
  console.log(`  Level: ${fullConfig.logging.level}`);
  console.log(`  Directory: ${config.getLogDirectory()}`);
  console.log(`  Format: ${fullConfig.logging.format}`);
  console.log(`  Rotation: ${fullConfig.logging.rotation}`);

  console.log("\n📌 Events:");
  console.log(
    `  Notification: ${fullConfig.events.notification.enabled ? "✅ Enabled" : "❌ Disabled"}`,
  );
  if (fullConfig.events.notification.enabled) {
    console.log(
      `    Extract Context: ${fullConfig.events.notification.extract_context}`,
    );
    console.log(
      `    Context Length: ${fullConfig.events.notification.context_length}`,
    );
  }
  console.log(
    `  Session End: ${fullConfig.events.session_end.enabled ? "✅ Enabled" : "❌ Disabled"}`,
  );

  console.log("\n🔔 Notifiers:");

  if (fullConfig.notifiers.webhook) {
    const webhook = fullConfig.notifiers.webhook;
    console.log(`  Webhook: ${webhook.enabled ? "✅ Enabled" : "❌ Disabled"}`);
    if (webhook.enabled) {
      console.log(`    URL: ${webhook.url}`);
      console.log(`    Timeout: ${webhook.timeout}s`);
      console.log(`    Max Attempts: ${webhook.retry.max_attempts}`);
      console.log(`    Backoff: ${webhook.retry.backoff}`);
    }
  }

  const macos = fullConfig.notifiers.macos;
  console.log(`  macOS: ${macos.enabled ? "✅ Enabled" : "❌ Disabled"}`);
  if (macos.enabled) {
    console.log(`    Title: ${macos.title}`);
    console.log(`    Sound: ${macos.sound}`);
    console.log(`    Actions: ${macos.actions.length} configured`);
  }

  console.log("\n" + "─".repeat(60));
}

async function validateConfig(): Promise<void> {
  console.log("🔍 Validating configuration...\n");

  const config = new ConfigManager();
  const validation = config.validate();

  if (validation.valid) {
    console.log("✅ Configuration is valid!");
    const configPath = config.getConfigPath();
    if (configPath) {
      console.log(`📁 Config file: ${configPath}`);
    }
  } else {
    console.error("❌ Configuration validation failed:\n");
    for (const error of validation.errors) {
      console.error(`  - ${error}`);
    }
    process.exit(1);
  }
}
