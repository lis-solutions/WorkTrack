/*
  # Communication and Notification Tables

  Internal messaging, chat system, and notification infrastructure for real-time communication.

  ## Tables
  - `chat_channels`: Group conversations (task-based, department-based)
  - `chat_messages`: Individual messages with metadata
  - `chat_members`: Channel membership with read/unread tracking
  - `notifications`: In-app notification system
  - `notification_preferences`: User-customizable notification settings

  ## Features
  - Real-time WebSockets support via Supabase Realtime
  - Thread-like conversations via task ID
  - Read receipts and typing indicators
  - Notification preferences per user
*/

-- Chat Channels: Group conversations
CREATE TABLE IF NOT EXISTS chat_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  channel_type text DEFAULT 'general', -- general, task, department, direct
  task_id uuid REFERENCES tasks(id) ON DELETE SET NULL,
  department_id uuid REFERENCES departments(id) ON DELETE SET NULL,
  is_active boolean DEFAULT true,
  created_by_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_chat_channels_org_id ON chat_channels(organization_id);
CREATE INDEX idx_chat_channels_task_id ON chat_channels(task_id);
CREATE INDEX idx_chat_channels_dept_id ON chat_channels(department_id);

ALTER TABLE chat_channels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view org chat channels"
  ON chat_channels FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = chat_channels.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

-- Chat Messages: Individual messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  channel_id uuid NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  message text NOT NULL,
  attachments jsonb DEFAULT '[]',
  edited_at timestamptz,
  is_deleted boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_chat_messages_org_id ON chat_messages(organization_id);
CREATE INDEX idx_chat_messages_channel_id ON chat_messages(channel_id);
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at DESC);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages in org channels"
  ON chat_messages FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = chat_messages.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own messages"
  ON chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = user_id
    )
  );

-- Chat Members: Channel membership
CREATE TABLE IF NOT EXISTS chat_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id uuid NOT NULL REFERENCES chat_channels(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role text DEFAULT 'member', -- admin, member, readonly
  last_read_at timestamptz,
  joined_at timestamptz DEFAULT now(),
  UNIQUE(channel_id, user_id)
);

CREATE INDEX idx_chat_members_channel_id ON chat_members(channel_id);
CREATE INDEX idx_chat_members_user_id ON chat_members(user_id);

ALTER TABLE chat_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own membership"
  ON chat_members FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.id = user_id
    )
  );

-- Notifications: In-app notification system
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  recipient_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES users(id) ON DELETE SET NULL,
  notification_type text NOT NULL, -- task_assigned, task_completed, message, mention, comment, etc.
  resource_type text, -- task, message, user, etc.
  resource_id uuid,
  title text NOT NULL,
  message text,
  action_url text,
  is_read boolean DEFAULT false,
  read_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_notifications_org_id ON notifications(organization_id);
CREATE INDEX idx_notifications_recipient_id ON notifications(recipient_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = notifications.organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = recipient_id
    )
  );

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = notifications.organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = recipient_id
    )
  );

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (organization_id IS NOT NULL);

-- Notification Preferences: User-customizable settings
CREATE TABLE IF NOT EXISTS notification_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  task_assigned boolean DEFAULT true,
  task_commented boolean DEFAULT true,
  task_completed boolean DEFAULT false,
  new_message boolean DEFAULT true,
  mention boolean DEFAULT true,
  daily_digest boolean DEFAULT false,
  quiet_hours_start time,
  quiet_hours_end time,
  timezone text DEFAULT 'UTC',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_notification_preferences_user_id ON notification_preferences(user_id);

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences"
  ON notification_preferences FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.id = user_id
    )
  );

CREATE POLICY "Users can update own preferences"
  ON notification_preferences FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.id = user_id
    )
  );

-- Create default notification preferences for new users (via trigger)
CREATE OR REPLACE FUNCTION create_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notification_preferences (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_create_notification_preferences
AFTER INSERT ON users
FOR EACH ROW EXECUTE FUNCTION create_notification_preferences();
