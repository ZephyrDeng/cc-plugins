/**
 * Claude Code Hook Event Types
 * Based on official documentation: https://docs.claude.com/en/docs/claude-code/hooks
 */

// ==================== Common Fields ====================

export interface BaseHookInput {
  session_id: string;
  transcript_path: string;
  cwd: string;
  permission_mode: "default" | "plan" | "acceptEdits" | "bypassPermissions";
  hook_event_name: string;
}

// ==================== Notification Event ====================

export interface NotificationInput extends BaseHookInput {
  hook_event_name: "Notification";
  message: string;
  notification_type?: "waiting_for_input" | "permission_required" | "idle";
}

// ==================== Session End Event ====================

export interface SessionEndInput extends BaseHookInput {
  hook_event_name: "SessionEnd";
  reason: "clear" | "logout" | "prompt_input_exit" | "other";
}

// ==================== Stop Event ====================

export interface StopInput extends BaseHookInput {
  hook_event_name: "Stop";
  stop_hook_active: boolean;
}

// ==================== Union Type ====================

export type HookInput = NotificationInput | SessionEndInput | StopInput;

// ==================== Hook Output ====================

export interface HookOutput {
  continue?: boolean;
  stopReason?: string;
  suppressOutput?: boolean;
  systemMessage?: string;
}

// ==================== Context Types ====================

export type MessageType = "question" | "confirmation" | "choice" | "info";

export interface ExtractedContext {
  last_message: string;
  message_type: MessageType;
}

// ==================== Notification Event Types ====================

export interface NotificationEvent {
  type: "notification";
  input: NotificationInput;
  context?: ExtractedContext;
}

export interface SessionEndEvent {
  type: "session_end";
  input: SessionEndInput | StopInput;
}

export type EventType = NotificationEvent | SessionEndEvent;
