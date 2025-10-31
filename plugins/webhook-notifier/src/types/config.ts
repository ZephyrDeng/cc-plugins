/**
 * Configuration types and Zod schemas
 */
import { z } from "zod";

// ==================== Logging Config ====================

export const LogLevelSchema = z.enum(["debug", "info", "warn", "error"]);
export type LogLevel = z.infer<typeof LogLevelSchema>;

export const LogFormatSchema = z.enum(["json", "text"]);
export type LogFormat = z.infer<typeof LogFormatSchema>;

export const LogRotationSchema = z.enum(["daily", "size"]);
export type LogRotation = z.infer<typeof LogRotationSchema>;

export const LoggingConfigSchema = z.object({
  level: LogLevelSchema.default("info"),
  directory: z.string().default("~/.claude/webhook-notifier/logs"),
  format: LogFormatSchema.default("json"),
  rotation: LogRotationSchema.default("daily"),
});
export type LoggingConfig = z.infer<typeof LoggingConfigSchema>;

// ==================== Events Config ====================

export const NotificationEventConfigSchema = z.object({
  enabled: z.boolean().default(true),
  extract_context: z.boolean().default(true),
  context_length: z.number().int().min(50).max(500).default(200),
});
export type NotificationEventConfig = z.infer<
  typeof NotificationEventConfigSchema
>;

export const SessionEndEventConfigSchema = z.object({
  enabled: z.boolean().default(true),
});
export type SessionEndEventConfig = z.infer<typeof SessionEndEventConfigSchema>;

export const EventsConfigSchema = z.object({
  notification: NotificationEventConfigSchema.default({}),
  session_end: SessionEndEventConfigSchema.default({}),
});
export type EventsConfig = z.infer<typeof EventsConfigSchema>;

// ==================== Webhook Notifier Config ====================

export const RetryBackoffSchema = z.enum(["linear", "exponential"]);
export type RetryBackoff = z.infer<typeof RetryBackoffSchema>;

export const RetryConfigSchema = z.object({
  enabled: z.boolean().default(false),
  max_attempts: z.number().int().min(1).max(10).default(3),
  backoff: RetryBackoffSchema.default("exponential"),
});
export type RetryConfig = z.infer<typeof RetryConfigSchema>;

export const PayloadConfigSchema = z.object({
  include: z
    .array(
      z.enum([
        "session_id",
        "timestamp",
        "project_info",
        "git_info",
        "context",
        "transcript_path",
      ]),
    )
    .default(["session_id", "timestamp", "project_info", "git_info"]),
  exclude: z.array(z.string()).default([]),
  custom_fields: z.record(z.any()).default({}),
});
export type PayloadConfig = z.infer<typeof PayloadConfigSchema>;

export const WebhookNotifierConfigSchema = z.object({
  enabled: z.boolean().default(true),
  url: z.string().url(),
  timeout: z.number().int().min(1).max(60).default(10),
  retry: RetryConfigSchema.default({}),
  headers: z.record(z.string()).default({}),
  payload: PayloadConfigSchema.default({}),
});
export type WebhookNotifierConfig = z.infer<typeof WebhookNotifierConfigSchema>;

// ==================== macOS Notifier Config ====================

export const MacOSNotificationActionSchema = z.object({
  label: z.string(),
  command: z.string(),
});
export type MacOSNotificationAction = z.infer<
  typeof MacOSNotificationActionSchema
>;

export const MacOSNotificationTemplateSchema = z.object({
  title: z.string().default("{{title}}"),
  subtitle: z.string().optional(),
  message: z.string().default("{{message}}"),
});
export type MacOSNotificationTemplate = z.infer<
  typeof MacOSNotificationTemplateSchema
>;

export const MacOSNotifierConfigSchema = z.object({
  enabled: z.boolean().default(false),
  title: z.string().default("Claude Code"),
  sound: z.string().default("default"),
  actions: z.array(MacOSNotificationActionSchema).default([]),
  templates: z
    .object({
      notification: MacOSNotificationTemplateSchema.default({}),
      session_end: MacOSNotificationTemplateSchema.default({}),
    })
    .default({}),
});
export type MacOSNotifierConfig = z.infer<typeof MacOSNotifierConfigSchema>;

// ==================== Notifiers Config ====================

export const NotifiersConfigSchema = z.object({
  webhook: WebhookNotifierConfigSchema.optional(),
  macos: MacOSNotifierConfigSchema.default({}),
});
export type NotifiersConfig = z.infer<typeof NotifiersConfigSchema>;

// ==================== Root Config ====================

export const ConfigSchema = z.object({
  logging: LoggingConfigSchema.default({}),
  events: EventsConfigSchema.default({}),
  notifiers: NotifiersConfigSchema,
});
export type Config = z.infer<typeof ConfigSchema>;

// ==================== Default Config ====================

export const DEFAULT_CONFIG: Config = {
  logging: {
    level: "info",
    directory: "~/.claude/webhook-notifier/logs",
    format: "json",
    rotation: "daily",
  },
  events: {
    notification: {
      enabled: true,
      extract_context: true,
      context_length: 200,
    },
    session_end: {
      enabled: true,
    },
  },
  notifiers: {
    macos: {
      enabled: false,
      title: "Claude Code",
      sound: "default",
      actions: [],
      templates: {
        notification: {
          title: "{{title}}",
          subtitle: "等待 {{message_type}}",
          message: "{{last_message}}",
        },
        session_end: {
          title: "{{title}}",
          subtitle: "会话结束",
          message: "原因: {{reason}}",
        },
      },
    },
  },
};
