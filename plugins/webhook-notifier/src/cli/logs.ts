/**
 * CLI Logs Command
 * 查看通知日志
 */
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join } from "node:path";
import { ConfigManager } from "../core/config.js";

interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  meta?: any;
}

export async function logsCommand(options: {
  lines?: string;
  follow?: boolean;
  level?: string;
}): Promise<void> {
  try {
    const config = new ConfigManager();
    const logDir = config.getLogDirectory();

    if (!existsSync(logDir)) {
      console.error(`❌ Log directory not found: ${logDir}`);
      console.log("\n💡 No logs have been generated yet");
      process.exit(1);
    }

    const lines = Number.parseInt(options.lines || "20", 10);
    const levelFilter = options.level?.toLowerCase();

    if (options.follow) {
      console.log("⚠️  Follow mode not implemented yet");
      console.log("💡 Use --lines to view recent logs instead");
      return;
    }

    // 获取最新的日志文件
    const logFiles = readdirSync(logDir)
      .filter((f) => f.endsWith(".log") && !f.includes("errors"))
      .map((f) => ({
        name: f,
        path: join(logDir, f),
        mtime: statSync(join(logDir, f)).mtime,
      }))
      .sort((a, b) => b.mtime.getTime() - a.mtime.getTime());

    if (logFiles.length === 0) {
      console.log("ℹ️  No log files found");
      return;
    }

    const latestLog = logFiles[0];
    console.log(`📋 Viewing: ${latestLog.name}`);
    console.log(`📁 Location: ${logDir}`);
    console.log("─".repeat(80));
    console.log();

    // 读取日志内容
    const content = readFileSync(latestLog.path, "utf-8");
    const allLines = content.trim().split("\n").filter(Boolean);

    // 解析并过滤日志
    let logEntries: LogEntry[] = [];

    for (const line of allLines) {
      try {
        const entry: LogEntry = JSON.parse(line);

        // 级别过滤
        if (levelFilter && entry.level.toLowerCase() !== levelFilter) {
          continue;
        }

        logEntries.push(entry);
      } catch {
        // 非 JSON 格式的行，直接显示
        logEntries.push({
          timestamp: "",
          level: "info",
          message: line,
        });
      }
    }

    // 只显示最后 N 行
    const displayLines = logEntries.slice(-lines);

    // 格式化输出
    for (const entry of displayLines) {
      const levelIcon = getLevelIcon(entry.level);
      const timestamp = entry.timestamp
        ? new Date(entry.timestamp).toLocaleString()
        : "";

      let output = `${levelIcon} ${timestamp} ${entry.message}`;

      if (entry.meta) {
        output += `\n   ${JSON.stringify(entry.meta)}`;
      }

      console.log(output);
    }

    console.log();
    console.log("─".repeat(80));
    console.log(
      `Showing last ${displayLines.length} of ${logEntries.length} entries`,
    );

    if (levelFilter) {
      console.log(`Filtered by level: ${levelFilter}`);
    }
  } catch (error) {
    console.error("❌ Failed to read logs:", error);
    process.exit(1);
  }
}

function getLevelIcon(level: string): string {
  switch (level.toLowerCase()) {
    case "error":
      return "❌";
    case "warn":
      return "⚠️ ";
    case "info":
      return "ℹ️ ";
    case "debug":
      return "🔍";
    default:
      return "  ";
  }
}
