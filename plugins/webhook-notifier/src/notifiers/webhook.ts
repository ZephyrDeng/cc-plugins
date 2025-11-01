/**
 * Webhook Notifier
 * 发送 HTTP POST 请求到配置的 webhook URL
 */
import type { ConfigManager } from "../core/config.js";
import type { Logger } from "../core/logger.js";
import type { EventType } from "../types/hook-events.js";
import type {
  NotificationPayload,
  NotificationResult,
  ProjectInfo,
  SessionEndPayload,
} from "../types/payload.js";
import { BaseNotifier } from "./base.js";
import { GitExtractor } from "../extractors/git.js";
import type { RetryConfig, WebhookNotifierConfig } from "../types/config.js";

export class WebhookNotifier extends BaseNotifier {
  private gitExtractor: GitExtractor;

  constructor(config: ConfigManager, logger: Logger) {
    super(config, logger);
    this.gitExtractor = new GitExtractor();
  }

  isEnabled(): boolean {
    const webhook = this.config.getSafe<WebhookNotifierConfig>(
      "notifiers.webhook"
    );
    return webhook?.enabled ?? false;
  }

  getName(): string {
    return "webhook";
  }

  async send(event: EventType): Promise<NotificationResult> {
    const webhookConfig =
      this.config.get<WebhookNotifierConfig>("notifiers.webhook");

    if (!webhookConfig) {
      return {
        success: false,
        notifier: "webhook",
        error: new Error("Webhook configuration not found"),
      };
    }

    if (!webhookConfig.url) {
      return {
        success: false,
        notifier: "webhook",
        error: new Error("Webhook URL is required"),
      };
    }

    try {
      const payload = this.buildPayload(event, webhookConfig);
      this.logger.debug("Webhook payload", payload);

      const response = await this.sendWithRetry(
        webhookConfig.url,
        payload,
        webhookConfig.timeout,
        webhookConfig.retry,
        webhookConfig.headers,
      );

      this.logger.info(`Webhook sent successfully (HTTP ${response.status})`);

      return {
        success: true,
        notifier: "webhook",
        response: {
          status: response.status,
          statusText: response.statusText,
        },
      };
    } catch (error) {
      this.logger.error("Webhook send failed", {
        error: error instanceof Error ? error.message : String(error),
      });

      return {
        success: false,
        notifier: "webhook",
        error: error instanceof Error ? error : new Error(String(error)),
      };
    }
  }

  /**
   * 发送 HTTP 请求（带重试）
   */
  private async sendWithRetry(
    url: string,
    payload: any,
    timeout: number,
    retryConfig: RetryConfig,
    headers: Record<string, string> = {},
  ): Promise<Response> {
    if (!retryConfig.enabled) {
      return this.sendRequest(url, payload, timeout, headers);
    }

    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= retryConfig.max_attempts; attempt++) {
      try {
        this.logger.debug(
          `Webhook attempt ${attempt}/${retryConfig.max_attempts}`,
        );
        return await this.sendRequest(url, payload, timeout, headers);
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));

        if (attempt < retryConfig.max_attempts) {
          const delay = this.calculateBackoff(attempt, retryConfig.backoff);
          this.logger.warn(
            `Webhook attempt ${attempt} failed, retrying in ${delay}ms`,
            { error: lastError.message },
          );
          await this.sleep(delay);
        }
      }
    }

    throw lastError || new Error("Webhook send failed");
  }

  /**
   * 发送单次 HTTP 请求
   */
  private async sendRequest(
    url: string,
    payload: any,
    timeout: number,
    headers: Record<string, string> = {},
  ): Promise<Response> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout * 1000);

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "User-Agent": "Claude-Code-Webhook-Notifier/2.0",
          ...headers,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return response;
    } finally {
      clearTimeout(timeoutId);
    }
  }

  /**
   * 计算退避延迟
   */
  private calculateBackoff(
    attempt: number,
    strategy: "linear" | "exponential",
  ): number {
    if (strategy === "linear") {
      return attempt * 1000; // 1s, 2s, 3s, ...
    } else {
      return Math.pow(2, attempt - 1) * 1000; // 1s, 2s, 4s, 8s, ...
    }
  }

  /**
   * 睡眠指定毫秒数
   */
  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * 构建 payload
   */
  private buildPayload(
    event: EventType,
    config: WebhookNotifierConfig,
  ): NotificationPayload | SessionEndPayload {
    const timestamp = new Date().toISOString();
    const source = "claude-code-webhook-notifier";

    if (event.type === "notification") {
      const payload: NotificationPayload = {
        event: "notification",
        timestamp,
        source,
        notification_type: event.input.notification_type || "waiting_for_input",
        message: event.input.message,
      };

      // 添加可选字段
      if (config.payload.include.includes("context") && event.context) {
        payload.context = event.context;
      }

      if (config.payload.include.includes("session_id")) {
        payload.session = {
          id: event.input.session_id,
        };
      }

      if (config.payload.include.includes("project_info")) {
        payload.project = this.extractProjectInfo(event);
      }

      // 合并自定义字段
      return {
        ...payload,
        ...config.payload.custom_fields,
      };
    } else {
      const payload: SessionEndPayload = {
        event: "session_end",
        timestamp,
        source,
        session: {
          id: event.input.session_id,
          reason: "reason" in event.input ? event.input.reason : "stopped",
        },
      };

      if (config.payload.include.includes("transcript_path")) {
        payload.session.transcript_path = event.input.transcript_path;
      }

      if (config.payload.include.includes("project_info")) {
        payload.project = this.extractProjectInfo(event);
      }

      // 合并自定义字段
      return {
        ...payload,
        ...config.payload.custom_fields,
      };
    }
  }

  /**
   * 提取项目信息
   */
  private extractProjectInfo(event: EventType): ProjectInfo {
    const projectDir = process.env.CLAUDE_PROJECT_DIR || event.input.cwd;
    const gitInfo = this.gitExtractor.extract(projectDir);

    return {
      directory: projectDir,
      git: gitInfo,
    };
  }
}
