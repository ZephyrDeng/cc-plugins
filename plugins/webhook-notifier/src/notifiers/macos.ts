/**
 * macOS Notifier
 * 使用 node-notifier 发送系统通知
 */
import notifier from "node-notifier";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import type { ConfigManager } from "../core/config.js";
import type { Logger } from "../core/logger.js";
import type { EventType } from "../types/hook-events.js";
import type { NotificationResult } from "../types/payload.js";
import { BaseNotifier } from "./base.js";
import type { MacOSNotifierConfig } from "../types/config.js";

const execAsync = promisify(exec);

interface NotificationContent {
  title: string;
  subtitle?: string;
  message: string;
}

export class MacOSNotifier extends BaseNotifier {
  isEnabled(): boolean {
    return (
      process.platform === "darwin" &&
      this.config.get<boolean>("notifiers.macos.enabled")
    );
  }

  getName(): string {
    return "macos";
  }

  async send(event: EventType): Promise<NotificationResult> {
    if (!this.isEnabled()) {
      return {
        success: false,
        notifier: "macos",
        error: new Error(
          "macOS notifier is not enabled or not on macOS platform",
        ),
      };
    }

    const macosConfig = this.config.get<MacOSNotifierConfig>("notifiers.macos");

    try {
      const content = this.formatNotification(event, macosConfig);
      await this.sendNotification(content, macosConfig);

      this.logger.info("macOS notification sent successfully");

      return {
        success: true,
        notifier: "macos",
      };
    } catch (error) {
      this.logger.error("macOS notification failed", {
        error: error instanceof Error ? error.message : String(error),
      });

      return {
        success: false,
        notifier: "macos",
        error: error instanceof Error ? error : new Error(String(error)),
      };
    }
  }

  /**
   * 发送系统通知
   */
  private sendNotification(
    content: NotificationContent,
    config: MacOSNotifierConfig,
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      notifier.notify(
        {
          title: content.title,
          subtitle: content.subtitle,
          message: content.message,
          sound: config.sound,
          wait: true, // 等待用户交互
          actions: config.actions?.map((a) => a.label) || [],
        },
        (err, response, metadata) => {
          if (err) {
            reject(err);
            return;
          }

          // 处理点击回调
          if (
            metadata?.activationType === "actionClicked" &&
            metadata.activationValue
          ) {
            this.handleAction(metadata.activationValue, config);
          }

          resolve();
        },
      );
    });
  }

  /**
   * 处理通知动作点击
   */
  private handleAction(actionLabel: string, config: MacOSNotifierConfig): void {
    const action = config.actions?.find((a) => a.label === actionLabel);

    if (action?.command) {
      this.logger.debug(`Executing action command: ${action.command}`);

      execAsync(action.command).catch((error) => {
        this.logger.error("Action command failed", {
          command: action.command,
          error: error.message,
        });
      });
    }
  }

  /**
   * 格式化通知内容
   */
  private formatNotification(
    event: EventType,
    config: MacOSNotifierConfig,
  ): NotificationContent {
    if (event.type === "notification") {
      const template = config.templates?.notification || {
        title: config.title,
        subtitle: "等待输入",
        message: "{{message}}",
      };

      const variables = {
        title: config.title,
        message_type: event.context?.message_type || "input",
        last_message: event.context?.last_message || event.input.message,
        message: event.input.message,
      };

      return {
        title: this.renderTemplate(template.title, variables),
        subtitle: template.subtitle
          ? this.renderTemplate(template.subtitle, variables)
          : undefined,
        message: this.renderTemplate(template.message, variables),
      };
    } else {
      const template = config.templates?.session_end || {
        title: config.title,
        subtitle: "会话结束",
        message: "原因: {{reason}}",
      };

      const variables = {
        title: config.title,
        reason: "reason" in event.input ? event.input.reason : "stopped",
        session_id: event.input.session_id,
      };

      return {
        title: this.renderTemplate(template.title, variables),
        subtitle: template.subtitle
          ? this.renderTemplate(template.subtitle, variables)
          : undefined,
        message: this.renderTemplate(template.message, variables),
      };
    }
  }

  /**
   * 渲染模板字符串
   * 支持 {{variable}} 语法
   */
  private renderTemplate(
    template: string,
    variables: Record<string, any>,
  ): string {
    return template.replace(/\{\{(\w+)\}\}/g, (_, key) => {
      return String(variables[key] || "");
    });
  }
}
