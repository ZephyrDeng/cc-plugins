/**
 * Configuration Manager
 * Loads and validates configuration from YAML or JSON files
 */
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { parse as parseYAML } from "yaml";
import { type Config, ConfigSchema, DEFAULT_CONFIG } from "../types/config.js";

export class ConfigManager {
  private config: Config;
  private configPath: string | null = null;

  constructor(configPath?: string) {
    if (configPath) {
      this.configPath = configPath;
      this.config = this.loadConfigFromPath(configPath);
    } else {
      const result = this.findAndLoadConfig();
      this.configPath = result.path;
      this.config = result.config;
    }
  }

  /**
   * 查找并加载配置文件
   */
  private findAndLoadConfig(): { config: Config; path: string | null } {
    const searchPaths = [
      // 用户级配置（优先）
      join(homedir(), ".claude/plugins/webhook-notifier/.webhookrc.yaml"),
      join(homedir(), ".claude/plugins/webhook-notifier/.webhookrc.yml"),
      join(homedir(), ".claude/plugins/webhook-notifier/.webhookrc.json"),

      // 项目级配置（向后兼容）
      join(process.cwd(), ".webhookrc.yaml"),
      join(process.cwd(), ".webhookrc.yml"),
      join(process.cwd(), ".webhookrc.json"),

      // 旧用户级配置（兼容旧版本）
      join(homedir(), ".webhookrc.yaml"),
      join(homedir(), ".webhookrc.yml"),
      join(homedir(), ".webhookrc.json"),
    ];

    for (const path of searchPaths) {
      if (existsSync(path)) {
        try {
          const config = this.loadConfigFromPath(path);
          return { config, path };
        } catch (error) {
          console.warn(`Failed to load config from ${path}:`, error);
          continue;
        }
      }
    }

    // 没找到配置文件，使用默认配置
    return { config: DEFAULT_CONFIG, path: null };
  }

  /**
   * 从指定路径加载配置
   */
  private loadConfigFromPath(path: string): Config {
    if (!existsSync(path)) {
      throw new Error(`Config file not found: ${path}`);
    }

    const content = readFileSync(path, "utf-8");
    let rawConfig: unknown;

    if (path.endsWith(".yaml") || path.endsWith(".yml")) {
      rawConfig = parseYAML(content);
    } else if (path.endsWith(".json")) {
      rawConfig = JSON.parse(content);
    } else {
      throw new Error(`Unsupported config file format: ${path}`);
    }

    // 解析环境变量
    const processed = this.processEnvVars(rawConfig);

    // 使用 Zod 验证和填充默认值
    const result = ConfigSchema.safeParse(processed);

    if (!result.success) {
      throw new Error(`Config validation failed: ${result.error.message}`);
    }

    return result.data;
  }

  /**
   * 递归处理环境变量替换
   * 支持 ${VAR_NAME} 语法
   */
  private processEnvVars(obj: any): any {
    if (typeof obj === "string") {
      return obj.replace(/\$\{(\w+)\}/g, (_, key) => {
        const value = process.env[key];
        if (value === undefined) {
          console.warn(`Environment variable ${key} is not defined`);
          return "";
        }
        return value;
      });
    }

    if (Array.isArray(obj)) {
      return obj.map((item) => this.processEnvVars(item));
    }

    if (obj !== null && typeof obj === "object") {
      const processed: Record<string, any> = {};
      for (const [key, value] of Object.entries(obj)) {
        processed[key] = this.processEnvVars(value);
      }
      return processed;
    }

    return obj;
  }

  /**
   * 获取完整配置
   */
  getConfig(): Config {
    return this.config;
  }

  /**
   * 使用路径获取嵌套配置值
   * @example get('logging.level') => 'info'
   * @example get('notifiers.webhook.url') => 'https://...'
   */
  get<T = any>(path: string): T {
    const parts = path.split(".");
    let value: any = this.config;

    for (const part of parts) {
      if (value === null || value === undefined) {
        throw new Error(`Config path not found: ${path}`);
      }
      value = value[part];
    }

    return value as T;
  }

  /**
   * 检查配置路径是否存在
   */
  has(path: string): boolean {
    try {
      this.get(path);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 安全获取配置值，不存在时返回默认值
   * @param path 配置路径
   * @param defaultValue 默认值
   * @returns 配置值或默认值
   */
  getSafe<T = any>(path: string, defaultValue?: T): T | undefined {
    try {
      return this.get<T>(path);
    } catch {
      return defaultValue;
    }
  }

  /**
   * 获取配置文件路径
   */
  getConfigPath(): string | null {
    return this.configPath;
  }

  /**
   * 验证配置完整性
   */
  validate(): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    // 检查 webhook 配置
    if (this.config.notifiers.webhook) {
      const webhook = this.config.notifiers.webhook;
      if (webhook.enabled && !webhook.url) {
        errors.push("Webhook URL is required when webhook notifier is enabled");
      }
    }

    // 检查 macOS 配置
    if (this.config.notifiers.macos?.enabled) {
      if (process.platform !== "darwin") {
        errors.push("macOS notifier can only be enabled on macOS platform");
      }
    }

    // 检查日志目录
    const logDir = this.expandPath(this.config.logging.directory);
    // 不检查目录是否存在，因为会自动创建

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  /**
   * 展开路径中的 ~ 为用户目录
   */
  expandPath(path: string): string {
    if (path.startsWith("~/")) {
      return join(homedir(), path.slice(2));
    }
    return path;
  }

  /**
   * 获取日志目录的绝对路径
   */
  getLogDirectory(): string {
    return this.expandPath(this.config.logging.directory);
  }

  /**
   * 获取指定 scope 的配置文件路径
   */
  static getConfigPath(scope: "user" | "project"): string {
    if (scope === "user") {
      return join(homedir(), ".claude/plugins/webhook-notifier/.webhookrc.yaml");
    }
    return join(process.cwd(), ".webhookrc.yaml");
  }
}
