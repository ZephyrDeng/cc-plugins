/**
 * Context Extractor
 * 从 transcript 文件提取最后一条 assistant 消息和消息类型
 */
import { existsSync, readFileSync } from "node:fs";
import type { ExtractedContext, MessageType } from "../types/hook-events.js";

interface TranscriptEntry {
  role: "user" | "assistant";
  content: string;
  [key: string]: any;
}

export class ContextExtractor {
  /**
   * 从 transcript 文件提取上下文
   */
  async extract(
    transcriptPath: string,
    maxLength: number = 200,
  ): Promise<ExtractedContext | null> {
    if (!existsSync(transcriptPath)) {
      return null;
    }

    try {
      // 读取文件最后 N 行（提高性能）
      const content = readFileSync(transcriptPath, "utf-8");
      const lines = content.trim().split("\n");

      // 从后往前查找最后一条 assistant 消息
      for (let i = lines.length - 1; i >= 0; i--) {
        try {
          const line = lines[i];
          if (!line) continue;
          const entry: TranscriptEntry = JSON.parse(line);

          if (entry.role === "assistant" && entry.content) {
            const lastMessage = this.truncate(entry.content, maxLength);
            const messageType = this.detectMessageType(lastMessage);

            return {
              last_message: lastMessage,
              message_type: messageType,
            };
          }
        } catch {
          // 跳过解析失败的行
          continue;
        }
      }

      return null;
    } catch (error) {
      console.error("Failed to extract context:", error);
      return null;
    }
  }

  /**
   * 截断消息到指定长度
   */
  private truncate(text: string, maxLength: number): string {
    if (text.length <= maxLength) {
      return text;
    }

    return text.slice(0, maxLength) + "...";
  }

  /**
   * 检测消息类型
   */
  private detectMessageType(message: string): MessageType {
    const lowerMessage = message.toLowerCase();

    // 1. Question: 包含问号或疑问词
    if (
      /[?？]/.test(message) ||
      /\b(how|what|why|when|where|which|who|吗|呢|如何|怎么|什么|哪|为什么|什么时候|哪里)\b/i.test(
        lowerMessage,
      )
    ) {
      return "question";
    }

    // 2. Confirmation: 包含确认相关词
    if (
      /\b(是否|同意|确认|可以吗|需要吗|要不要|approve|confirm|agree|okay|ok)\b/i.test(
        lowerMessage,
      )
    ) {
      return "confirmation";
    }

    // 3. Choice: 包含选项标记
    if (
      /\b([0-9]\.|选择|或者|还是|option|choose|select)\b/i.test(lowerMessage)
    ) {
      return "choice";
    }

    // 4. Info: 默认为普通信息
    return "info";
  }
}
