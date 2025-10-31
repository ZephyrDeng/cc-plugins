/**
 * Webhook Payload Types
 */
import type { ExtractedContext, MessageType } from "./hook-events.js";

// ==================== Git Info ====================

export interface GitInfo {
  branch: string | null;
  repo: string | null;
  commit: string | null;
}

// ==================== Project Info ====================

export interface ProjectInfo {
  directory: string;
  git?: GitInfo;
}

// ==================== Session Info ====================

export interface SessionInfo {
  id: string;
  reason?: string;
  transcript_path?: string;
}

// ==================== Base Payload ====================

export interface BasePayload {
  event: string;
  timestamp: string;
  source: string;
}

// ==================== Notification Payload ====================

export interface NotificationPayload extends BasePayload {
  event: "notification";
  notification_type: string;
  message: string;
  context?: ExtractedContext;
  session?: SessionInfo;
  project?: ProjectInfo;
}

// ==================== Session End Payload ====================

export interface SessionEndPayload extends BasePayload {
  event: "session_end";
  session: SessionInfo;
  project?: ProjectInfo;
}

// ==================== Union Type ====================

export type Payload = NotificationPayload | SessionEndPayload;

// ==================== Notification Result ====================

export interface NotificationResult {
  success: boolean;
  notifier: string;
  error?: Error;
  response?: any;
}
