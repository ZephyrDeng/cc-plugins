/**
 * Hook Entry Point
 * 从 stdin 读取 Hook 输入并处理
 */
import { stdin } from "node:process";
import { ConfigManager } from "./core/config.js";
import { Logger } from "./core/logger.js";
import { HookHandler } from "./core/hook-handler.js";
import type { HookInput } from "./types/hook-events.js";

/**
 * 从 stdin 读取所有输入
 */
function readStdin(): Promise<string> {
  return new Promise((resolve) => {
    let data = "";
    stdin.setEncoding("utf-8");

    stdin.on("data", (chunk) => {
      data += chunk;
    });

    stdin.on("end", () => {
      resolve(data);
    });
  });
}

/**
 * 处理 Hook 事件
 */
export async function handleHook(): Promise<void> {
  try {
    // 读取输入
    const input = await readStdin();

    if (!input.trim()) {
      console.error("Error: No input received");
      process.exit(1);
    }

    // 解析 JSON
    const hookInput: HookInput = JSON.parse(input);

    // 初始化配置和日志
    const config = new ConfigManager();
    const logger = new Logger(config);

    // 验证配置
    const validation = config.validate();
    if (!validation.valid) {
      logger.error("Configuration validation failed", {
        errors: validation.errors,
      });
      // 继续执行，但记录错误
    }

    // 处理 Hook
    const handler = new HookHandler(config, logger);
    const output = await handler.handle(hookInput);

    // 始终输出 JSON 结果到 stdout
    console.log(JSON.stringify(output));

    process.exit(0);
  } catch (error) {
    console.error("Hook handling failed:", error);
    process.exit(1);
  }
}
