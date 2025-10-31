/**
 * CLI Test Command
 * 测试通知配置
 */
import type { NotificationInput } from "../types/hook-events.js";
import { ConfigManager } from "../core/config.js";
import { Logger } from "../core/logger.js";
import { HookHandler } from "../core/hook-handler.js";

export async function testCommand(options: {
  notifier?: string;
}): Promise<void> {
  try {
    console.log("🧪 Testing notification configuration...\n");

    // 初始化配置和日志
    const config = new ConfigManager();
    const logger = new Logger(config);

    // 验证配置
    const validation = config.validate();
    if (!validation.valid) {
      console.error("❌ Configuration validation failed:");
      for (const error of validation.errors) {
        console.error(`  - ${error}`);
      }
      process.exit(1);
    }

    console.log("✅ Configuration is valid\n");

    // 创建测试事件
    const testEvent: NotificationInput = {
      hook_event_name: "Notification",
      message: "This is a test notification from webhook-notifier CLI",
      session_id: "test-cli-" + Date.now(),
      transcript_path: "/tmp/test-transcript.jsonl",
      cwd: process.cwd(),
      permission_mode: "default",
      notification_type: "waiting_for_input",
    };

    // 处理测试事件
    const handler = new HookHandler(config, logger);

    console.log("📤 Sending test notifications...\n");

    const output = await handler.handle(testEvent);

    if (output.continue) {
      console.log("✅ Test completed successfully!");
      console.log(
        "\n💡 Check logs for details:",
        config.getLogDirectory() + "/",
      );
    } else {
      console.error("❌ Test failed");
      if (output.systemMessage) {
        console.error("Error:", output.systemMessage);
      }
      process.exit(1);
    }
  } catch (error) {
    console.error("❌ Test failed:", error);
    process.exit(1);
  }
}
