/*
  # CMS, Announcements, and Dashboard Tables

  Content management, internal communications, and reporting infrastructure.

  ## Tables
  - `announcements`: Company-wide announcements
  - `knowledge_base`: Internal wiki/documentation
  - `dashboard_widgets`: Customizable dashboard components
  - `reports`: Saved reports for analytics

  ## Features
  - Rich content support for announcements
  - Searchable knowledge base
  - User-customizable dashboards
  - Scheduled report generation
*/

-- Announcements: Company-wide communications
CREATE TABLE IF NOT EXISTS announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  created_by_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  title text NOT NULL,
  content text NOT NULL,
  priority text DEFAULT 'normal', -- low, normal, high, urgent
  status text DEFAULT 'published', -- draft, published, archived
  published_at timestamptz,
  expiry_date timestamptz,
  target_roles jsonb DEFAULT '[]', -- Empty = all, otherwise specific roles
  attachments jsonb DEFAULT '[]',
  view_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_announcements_org_id ON announcements(organization_id);
CREATE INDEX idx_announcements_created_by ON announcements(created_by_id);
CREATE INDEX idx_announcements_status ON announcements(status);
CREATE INDEX idx_announcements_published_at ON announcements(published_at DESC);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view published announcements"
  ON announcements FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = announcements.organization_id
      AND users.auth_user_id = auth.uid()
      AND (announcements.status = 'published' OR announcements.created_by_id = users.id)
    )
  );

CREATE POLICY "Admins can create announcements"
  ON announcements FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = organization_id
      AND u.role IN ('owner', 'admin')
    )
  );

-- Knowledge Base: Internal wiki/documentation
CREATE TABLE IF NOT EXISTS knowledge_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  created_by_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  title text NOT NULL,
  content text NOT NULL,
  category text, -- policies, procedures, faqs, guides, etc.
  tags jsonb DEFAULT '[]',
  status text DEFAULT 'published', -- draft, published, archived
  view_count integer DEFAULT 0,
  version integer DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_knowledge_base_org_id ON knowledge_base(organization_id);
CREATE INDEX idx_knowledge_base_category ON knowledge_base(category);
CREATE INDEX idx_knowledge_base_status ON knowledge_base(status);

ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view published kb"
  ON knowledge_base FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = knowledge_base.organization_id
      AND users.auth_user_id = auth.uid()
      AND (knowledge_base.status = 'published' OR knowledge_base.created_by_id = users.id)
    )
  );

CREATE POLICY "Admins can manage kb"
  ON knowledge_base FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = organization_id
      AND u.role IN ('owner', 'admin')
    )
  );

-- Dashboard Widgets: Customizable dashboard components
CREATE TABLE IF NOT EXISTS dashboard_widgets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  widget_type text NOT NULL, -- tasks_summary, timesheet_summary, team_workload, attendance_rate, etc.
  title text NOT NULL,
  config jsonb DEFAULT '{}', -- Widget-specific configuration
  position integer DEFAULT 0, -- Order on dashboard
  width integer DEFAULT 1, -- 1-4 grid columns
  height integer DEFAULT 1, -- 1-3 grid rows
  is_visible boolean DEFAULT true,
  refresh_interval integer DEFAULT 300, -- Seconds
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_dashboard_widgets_org_id ON dashboard_widgets(organization_id);
CREATE INDEX idx_dashboard_widgets_user_id ON dashboard_widgets(user_id);

ALTER TABLE dashboard_widgets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own dashboard widgets"
  ON dashboard_widgets FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = dashboard_widgets.organization_id
      AND u.id = user_id
    )
  );

CREATE POLICY "Users can manage own dashboard"
  ON dashboard_widgets FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = organization_id
      AND u.id = user_id
    )
  );

CREATE POLICY "Users can update own widgets"
  ON dashboard_widgets FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = dashboard_widgets.organization_id
      AND u.id = user_id
    )
  );

-- Reports: Saved reports for analytics
CREATE TABLE IF NOT EXISTS reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  created_by_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  report_name text NOT NULL,
  report_type text NOT NULL, -- task_completion, timesheet_summary, attendance, utilization, etc.
  filters jsonb DEFAULT '{}',
  group_by text, -- user, department, date, priority, status, etc.
  metrics jsonb DEFAULT '[]', -- Fields to include in report
  date_range_start date,
  date_range_end date,
  format text DEFAULT 'json', -- json, csv, pdf (future)
  is_scheduled boolean DEFAULT false,
  schedule_frequency text, -- daily, weekly, monthly (if is_scheduled = true)
  last_generated_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_reports_org_id ON reports(organization_id);
CREATE INDEX idx_reports_created_by ON reports(created_by_id);
CREATE INDEX idx_reports_type ON reports(report_type);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view org reports"
  ON reports FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = reports.organization_id
      AND u.role IN ('owner', 'admin', 'manager')
    )
  );

CREATE POLICY "Admins can create reports"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = organization_id
      AND u.role IN ('owner', 'admin')
    )
  );

-- Report Data: Cached report results
CREATE TABLE IF NOT EXISTS report_data (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  data jsonb NOT NULL,
  generated_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

CREATE INDEX idx_report_data_report_id ON report_data(report_id);
CREATE INDEX idx_report_data_expires_at ON report_data(expires_at);

ALTER TABLE report_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view report data"
  ON report_data FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND EXISTS (
        SELECT 1 FROM reports r
        WHERE r.id = report_data.report_id
        AND r.organization_id = u.organization_id
        AND u.role IN ('owner', 'admin', 'manager')
      )
    )
  );

-- Create default dashboard widgets for new users
CREATE OR REPLACE FUNCTION create_default_dashboard_widgets()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO dashboard_widgets (organization_id, user_id, widget_type, title, position, width, height) VALUES
    (NEW.organization_id, NEW.id, 'tasks_summary', 'My Tasks', 0, 2, 1),
    (NEW.organization_id, NEW.id, 'timesheet_summary', 'Timesheet Status', 1, 2, 1),
    (NEW.organization_id, NEW.id, 'attendance_today', 'Attendance', 2, 1, 1);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_create_default_dashboard_widgets
AFTER INSERT ON users
FOR EACH ROW EXECUTE FUNCTION create_default_dashboard_widgets();
