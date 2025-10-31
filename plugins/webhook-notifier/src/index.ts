/**
 * Webhook Notifier Main Entry Point
 * 支持 Hook 模式和 CLI 模式
 */
import { stdin } from "node:process";
import { Command } from "commander";
import { handleHook } from "./hook.js";
import { testCommand } from "./cli/test.js";
import { configCommand } from "./cli/config.js";
import { logsCommand } from "./cli/logs.js";

// 主函数（包装 async 逻辑以支持 CommonJS）
(async () => {
  // 检测运行模式：
  // - 如果有命令行参数（除了 node 和脚本），则为 CLI 模式
  // - 否则检查 stdin 是否为 TTY，如果不是则为 Hook 模式
  const hasArgs = process.argv.length > 2;
  const isHookMode = !hasArgs && !stdin.isTTY;

  if (isHookMode) {
    // Hook 模式 - 处理来自 Claude Code 的事件
    await handleHook();
  } else {
    // CLI 模式 - 处理命令行命令
    const program = new Command();

    program
      .name("webhook")
      .description("Claude Code Webhook Notifier - 强大的通知系统")
      .version("2.0.0");

    // Test 命令
    program
      .command("test")
      .description("测试通知配置")
      .option(
        "-n, --notifier <type>",
        "指定通知器: webhook | macos | all",
        "all",
      )
      .action(testCommand);

    // Config 命令
    program
      .command("config")
      .description("配置管理")
      .option("-s, --show", "显示当前配置")
      .option("-i, --init", "初始化配置文件")
      .option("-v, --validate", "验证配置")
      .action(configCommand);

    // Logs 命令
    program
      .command("logs")
      .description("查看通知日志")
      .option("-n, --lines <number>", "显示行数", "20")
      .option("-f, --follow", "实时跟踪日志")
      .option("-l, --level <level>", "过滤日志级别")
      .action(logsCommand);

    program.parse();
  }
})().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
