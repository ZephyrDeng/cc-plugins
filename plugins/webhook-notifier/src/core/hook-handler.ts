/**
 * Hook Handler
 * 处理来自 Claude Code 的 Hook 事件
 */
import type { ConfigManager } from "./config.js";
import type { Logger } from "./logger.js";
import { ContextExtractor } from "../extractors/context.js";
import { WebhookNotifier, MacOSNotifier } from "../notifiers/index.js";
import type { BaseNotifier } from "../notifiers/base.js";
import type {
  HookInput,
  HookOutput,
  NotificationInput,
  SessionEndInput,
  StopInput,
  EventType,
  NotificationEvent,
  SessionEndEvent,
} from "../types/hook-events.js";

export class HookHandler {
  private contextExtractor: ContextExtractor;
  private notifiers: BaseNotifier[];

  constructor(
    private config: ConfigManager,
    private logger: Logger,
  ) {
    this.contextExtractor = new ContextExtractor();

    // 初始化所有通知器
    this.notifiers = [
      new WebhookNotifier(config, logger),
      new MacOSNotifier(config, logger),
    ];
  }

  /**
   * 处理 Hook 事件
   */
  async handle(input: HookInput): Promise<HookOutput> {
    this.logger.info(`Processing ${input.hook_event_name} event`, {
      session_id: input.session_id,
    });

    try {
      // 验证输入
      this.validateInput(input);

      // 根据事件类型路由
      const event = await this.createEvent(input);

      if (!event) {
        // 不支持的事件类型，静默忽略
        return { continue: true };
      }

      // 并行发送所有启用的通知
      const results = await this.sendNotifications(event);

      // 记录结果
      this.logResults(results);

      // 返回输出
      return this.createOutput(results);
    } catch (error) {
      this.logger.error("Hook handling failed", {
        error: error instanceof Error ? error.message : String(error),
      });

      // 即使失败也继续执行，不阻塞 Claude
      return { continue: true };
    }
  }

  /**
   * 验证输入
   */
  private validateInput(input: HookInput): void {
    if (!input.session_id) {
      throw new Error("session_id is required");
    }

    if (!input.hook_event_name) {
      throw new Error("hook_event_name is required");
    }
  }

  /**
   * 创建事件对象
   */
  private async createEvent(input: HookInput): Promise<EventType | null> {
    switch (input.hook_event_name) {
      case "Notification":
        return this.createNotificationEvent(input as NotificationInput);

      case "Stop":
      case "SessionEnd":
        return this.createSessionEndEvent(input as SessionEndInput | StopInput);

      default:
        this.logger.warn(
          `Unsupported event type: ${(input as HookInput).hook_event_name}`,
        );
        return null;
    }
  }

  /**
   * 创建 Notification 事件
   */
  private async createNotificationEvent(
    input: NotificationInput,
  ): Promise<NotificationEvent | null> {
    // 检查是否启用
    const enabled = this.config.get<boolean>("events.notification.enabled");
    if (!enabled) {
      this.logger.debug("Notification events are disabled");
      return null;
    }

    const event: NotificationEvent = {
      type: "notification",
      input,
    };

    // 提取上下文（如果启用）
    const extractContext = this.config.get<boolean>(
      "events.notification.extract_context",
    );
    if (extractContext && input.transcript_path) {
      const contextLength = this.config.get<number>(
        "events.notification.context_length",
      );
      const context = await this.contextExtractor.extract(
        input.transcript_path,
        contextLength,
      );

      if (context) {
        event.context = context;
        this.logger.debug("Context extracted", context);
      } else {
        this.logger.debug(
          "Failed to extract context, using basic notification",
        );
      }
    }

    return event;
  }

  /**
   * 创建 SessionEnd 事件
   */
  private createSessionEndEvent(
    input: SessionEndInput | StopInput,
  ): SessionEndEvent | null {
    // 检查是否启用
    const enabled = this.config.get<boolean>("events.session_end.enabled");
    if (!enabled) {
      this.logger.debug("Session end events are disabled");
      return null;
    }

    return {
      type: "session_end",
      input,
    };
  }

  /**
   * 发送所有启用的通知
   */
  private async sendNotifications(event: EventType) {
    const enabledNotifiers = this.notifiers.filter((n) => n.isEnabled());

    if (enabledNotifiers.length === 0) {
      this.logger.warn("No notifiers are enabled");
      return [];
    }

    this.logger.info(
      `Sending notifications via ${enabledNotifiers.length} notifiers`,
      {
        notifiers: enabledNotifiers.map((n) => n.getName()),
      },
    );

    // 并行发送
    const results = await Promise.allSettled(
      enabledNotifiers.map((notifier) => notifier.send(event)),
    );

    return results.map((result, index) => ({
      notifier: enabledNotifiers[index]?.getName(),
      result,
    }));
  }

  /**
   * 记录结果
   */
  private logResults(
    results: Array<{
      notifier?: string;
      result: PromiseSettledResult<any>;
    }>,
  ): void {
    for (const { notifier, result } of results) {
      if (result.status === "fulfilled") {
        const value = result.value;
        if (value.success) {
          this.logger.info(`Notifier ${notifier} succeeded`);
        } else {
          this.logger.error(`Notifier ${notifier} failed`, {
            error: value.error?.message,
          });
        }
      } else {
        this.logger.error(`Notifier ${notifier} threw exception`, {
          error: result.reason,
        });
      }
    }
  }

  /**
   * 创建输出
   */
  private createOutput(
    results: Array<{
      notifier?: string;
      result: PromiseSettledResult<any>;
    }>,
  ): HookOutput {
    // 统计成功/失败数
    const successCount = results.filter(
      (r) => r.result.status === "fulfilled" && r.result.value.success,
    ).length;

    const totalCount = results.length;

    // 即使所有通知失败，也继续执行（不阻塞 Claude）
    return {
      continue: true,
      suppressOutput: true, // 不在 transcript 中显示
      systemMessage:
        successCount === totalCount
          ? undefined
          : `Notifications: ${successCount}/${totalCount} succeeded`,
    };
  }
}
