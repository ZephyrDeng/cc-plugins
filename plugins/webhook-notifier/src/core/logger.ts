/**
 * Logger System
 * Supports both JSON and text formats with daily rotation
 */
import { existsSync, mkdirSync, appendFileSync } from "node:fs";
import { join } from "node:path";
import type { ConfigManager } from "./config.js";
import type { LogLevel, LogFormat } from "../types/config.js";

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  meta?: any;
}

export class Logger {
  private logDir: string;
  private logLevel: LogLevel;
  private logFormat: LogFormat;

  private readonly levelPriority: Record<LogLevel, number> = {
    debug: 0,
    info: 1,
    warn: 2,
    error: 3,
  };

  constructor(private config: ConfigManager) {
    this.logDir = this.config.getLogDirectory();
    this.logLevel = this.config.get<LogLevel>("logging.level");
    this.logFormat = this.config.get<LogFormat>("logging.format");

    this.ensureLogDirectory();
  }

  /**
   * 确保日志目录存在
   */
  private ensureLogDirectory(): void {
    if (!existsSync(this.logDir)) {
      mkdirSync(this.logDir, { recursive: true });
    }
  }

  /**
   * 检查是否应该记录该级别的日志
   */
  private shouldLog(level: LogLevel): boolean {
    return this.levelPriority[level] >= this.levelPriority[this.logLevel];
  }

  /**
   * 获取当前日期字符串（用于日志文件名）
   */
  private getDateString(): string {
    const now = new Date();
    return now.toISOString().split("T")[0] ?? "unknown";
  }

  /**
   * 格式化日志条目
   */
  private formatLogEntry(entry: LogEntry): string {
    if (this.logFormat === "json") {
      return JSON.stringify(entry);
    }

    // Text format
    let line = `[${entry.timestamp}] ${entry.level.toUpperCase()}: ${entry.message}`;

    if (entry.meta) {
      line += `\n  Meta: ${JSON.stringify(entry.meta, null, 2)}`;
    }

    return line;
  }

  /**
   * 写入日志
   */
  private writeLog(level: LogLevel, message: string, meta?: any): void {
    if (!this.shouldLog(level)) {
      return;
    }

    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      meta,
    };

    const formattedLog = this.formatLogEntry(entry);

    // 写入日志文件（按日期分文件）
    const dateStr = this.getDateString();
    const logFile = join(this.logDir, `${dateStr}.log`);

    try {
      appendFileSync(logFile, formattedLog + "\n");
    } catch (error) {
      // 写入日志失败，输出到 stderr
      console.error("Failed to write log:", error);
    }

    // 错误日志额外写入 errors.log
    if (level === "error") {
      const errorFile = join(this.logDir, "errors.log");
      try {
        appendFileSync(errorFile, formattedLog + "\n");
      } catch (error) {
        console.error("Failed to write error log:", error);
      }
    }
  }

  /**
   * Debug 日志
   */
  debug(message: string, meta?: any): void {
    this.writeLog("debug", message, meta);
  }

  /**
   * Info 日志
   */
  info(message: string, meta?: any): void {
    this.writeLog("info", message, meta);
  }

  /**
   * Warning 日志
   */
  warn(message: string, meta?: any): void {
    this.writeLog("warn", message, meta);
  }

  /**
   * Error 日志
   */
  error(message: string, meta?: any): void {
    this.writeLog("error", message, meta);

    // 对于错误，同时输出到 stderr
    console.error(`[ERROR] ${message}`, meta || "");
  }

  /**
   * 获取日志文件路径
   */
  getLogFilePath(date?: string): string {
    const dateStr = date || this.getDateString();
    return join(this.logDir, `${dateStr}.log`);
  }

  /**
   * 获取错误日志文件路径
   */
  getErrorLogPath(): string {
    return join(this.logDir, "errors.log");
  }
}
