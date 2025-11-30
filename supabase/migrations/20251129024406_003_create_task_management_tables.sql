/*
  # Task Management and Work Tracking Tables

  Core MVP features: Task creation, assignment, status tracking, and time logging.

  ## Tables
  - `tasks`: Work items with assignment and status
  - `task_comments`: Comments and collaboration on tasks
  - `timesheets`: Daily/weekly time entries
  - `attendance`: Check-in/out for presence tracking
  - `time_logs`: Time logged against specific tasks

  ## Security
  - All tables enforce organization_id isolation
  - RLS prevents cross-organization data leakage
  - Users can only modify their own entries unless admin/manager
*/

-- Tasks: Core work items
CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  created_by_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  assigned_to_id uuid REFERENCES users(id) ON DELETE SET NULL,
  title text NOT NULL,
  description text,
  priority text DEFAULT 'medium', -- low, medium, high, urgent
  status text DEFAULT 'todo', -- todo, in_progress, review, done, cancelled
  due_date date,
  estimated_hours numeric(5,2),
  actual_hours numeric(5,2) DEFAULT 0,
  completion_percentage integer DEFAULT 0,
  tags jsonb DEFAULT '[]',
  attachments jsonb DEFAULT '[]',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_tasks_org_id ON tasks(organization_id);
CREATE INDEX idx_tasks_created_by ON tasks(created_by_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tasks in their organization"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = tasks.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Any org user can create tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Task creator or assignee can update"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = tasks.organization_id
      AND u.auth_user_id = auth.uid()
      AND (
        u.id = tasks.created_by_id 
        OR u.id = tasks.assigned_to_id
        OR u.role IN ('owner', 'admin', 'manager')
      )
    )
  );

-- Task Comments: Collaboration
CREATE TABLE IF NOT EXISTS task_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  comment text NOT NULL,
  attachments jsonb DEFAULT '[]',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_task_comments_org_id ON task_comments(organization_id);
CREATE INDEX idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX idx_task_comments_user_id ON task_comments(user_id);

ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view comments on org tasks"
  ON task_comments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = task_comments.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create task comments"
  ON task_comments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = user_id
    )
  );

-- Timesheets: Daily/weekly time entries
CREATE TABLE IF NOT EXISTS timesheets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entry_date date NOT NULL,
  hours_worked numeric(5,2) DEFAULT 0,
  status text DEFAULT 'draft', -- draft, submitted, approved, rejected
  notes text,
  approved_by_id uuid REFERENCES users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, user_id, entry_date)
);

CREATE INDEX idx_timesheets_org_id ON timesheets(organization_id);
CREATE INDEX idx_timesheets_user_id ON timesheets(user_id);
CREATE INDEX idx_timesheets_entry_date ON timesheets(entry_date);
CREATE INDEX idx_timesheets_status ON timesheets(status);

ALTER TABLE timesheets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own timesheets"
  ON timesheets FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = timesheets.organization_id
      AND u.auth_user_id = auth.uid()
      AND (u.id = timesheets.user_id OR u.role IN ('owner', 'admin', 'manager'))
    )
  );

CREATE POLICY "Users can create own timesheets"
  ON timesheets FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = user_id
    )
  );

CREATE POLICY "Users can update own timesheets"
  ON timesheets FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = timesheets.organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = timesheets.user_id
    )
  );

-- Attendance: Check-in/out for presence
CREATE TABLE IF NOT EXISTS attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  check_in_time timestamptz NOT NULL,
  check_out_time timestamptz,
  hours_present numeric(5,2),
  location text,
  device_info jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_attendance_org_id ON attendance(organization_id);
CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_attendance_check_in_time ON attendance(check_in_time DESC);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own attendance"
  ON attendance FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = attendance.organization_id
      AND u.auth_user_id = auth.uid()
      AND (u.id = attendance.user_id OR u.role IN ('owner', 'admin', 'manager'))
    )
  );

CREATE POLICY "Users can create own attendance"
  ON attendance FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = user_id
    )
  );

CREATE POLICY "Users can update own attendance"
  ON attendance FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = attendance.organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = attendance.user_id
    )
  );

-- Time Logs: Time logged against tasks
CREATE TABLE IF NOT EXISTS time_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  duration_minutes integer NOT NULL,
  description text,
  log_date date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_time_logs_org_id ON time_logs(organization_id);
CREATE INDEX idx_time_logs_task_id ON time_logs(task_id);
CREATE INDEX idx_time_logs_user_id ON time_logs(user_id);
CREATE INDEX idx_time_logs_date ON time_logs(log_date);

ALTER TABLE time_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view time logs in org"
  ON time_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = time_logs.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own time logs"
  ON time_logs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = user_id
    )
  );

CREATE POLICY "Users can update own time logs"
  ON time_logs FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.organization_id = time_logs.organization_id
      AND u.auth_user_id = auth.uid()
      AND u.id = time_logs.user_id
    )
  );
