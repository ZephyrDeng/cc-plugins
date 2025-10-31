/**
 * Base Notifier
 * 所有通知器的抽象基类
 */
import type { ConfigManager } from "../core/config.js";
import type { Logger } from "../core/logger.js";
import type { EventType } from "../types/hook-events.js";
import type { NotificationResult } from "../types/payload.js";

export abstract class BaseNotifier {
  constructor(
    protected config: ConfigManager,
    protected logger: Logger,
  ) {}

  /**
   * 检查通知器是否启用
   */
  abstract isEnabled(): boolean;

  /**
   * 发送通知
   */
  abstract send(event: EventType): Promise<NotificationResult>;

  /**
   * 获取通知器名称
   */
  abstract getName(): string;
}
