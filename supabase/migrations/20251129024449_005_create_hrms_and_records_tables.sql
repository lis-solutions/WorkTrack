/*
  # HRMS and Records Management Tables

  Employee records, documents, leaves, and HR-related data.

  ## Tables
  - `employee_records`: Personal and professional information
  - `documents`: Uploaded documents (contracts, pay slips, etc.)
  - `leave_requests`: Leave applications and approvals
  - `leave_types`: Organization-defined leave categories
  - `employee_skills`: Skills and competencies

  ## Features
  - Secure document storage with versioning
  - Leave management workflow
  - Skill tracking for resource planning
*/

-- Employee Records: Personal and professional information
CREATE TABLE IF NOT EXISTS employee_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  employee_id text UNIQUE, -- Custom employee ID per org
  employment_type text DEFAULT 'full-time', -- full-time, part-time, contract, internship
  employment_status text DEFAULT 'active', -- active, on-leave, suspended, terminated
  date_of_joining date,
  date_of_birth date,
  manager_id uuid REFERENCES users(id) ON DELETE SET NULL,
  designation text,
  bank_account_number text,
  tax_id text,
  emergency_contact_name text,
  emergency_contact_phone text,
  address text,
  city text,
  state text,
  country text,
  postal_code text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_employee_records_org_id ON employee_records(organization_id);
CREATE INDEX idx_employee_records_user_id ON employee_records(user_id);
CREATE INDEX idx_employee_records_manager_id ON employee_records(manager_id);

ALTER TABLE employee_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own record"
  ON employee_records FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.id = user_id
      AND u.organization_id = employee_records.organization_id
    )
  );

CREATE POLICY "Managers can view team records"
  ON employee_records FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = employee_records.organization_id
      AND (u.role IN ('owner', 'admin') OR u.id = manager_id)
    )
  );

-- Documents: Uploaded documents with versioning
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  document_type text NOT NULL, -- contract, pay_slip, certification, offer_letter, etc.
  file_name text NOT NULL,
  file_path text NOT NULL, -- Storage path
  file_size integer,
  mime_type text,
  version integer DEFAULT 1,
  is_latest boolean DEFAULT true,
  uploaded_by_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_documents_org_id ON documents(organization_id);
CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_is_latest ON documents(is_latest);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = documents.organization_id
      AND (u.id = user_id OR u.role IN ('owner', 'admin'))
    )
  );

CREATE POLICY "Users can upload documents"
  ON documents FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = organization_id
    )
  );

-- Leave Types: Organization-defined leave categories
CREATE TABLE IF NOT EXISTS leave_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  annual_quota integer DEFAULT 0, -- 0 means unlimited
  is_paid boolean DEFAULT true,
  requires_approval boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, name)
);

CREATE INDEX idx_leave_types_org_id ON leave_types(organization_id);

ALTER TABLE leave_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view leave types in org"
  ON leave_types FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = leave_types.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

-- Leave Requests: Leave applications and approvals
CREATE TABLE IF NOT EXISTS leave_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  leave_type_id uuid NOT NULL REFERENCES leave_types(id) ON DELETE RESTRICT,
  start_date date NOT NULL,
  end_date date NOT NULL,
  duration_days integer NOT NULL,
  reason text,
  status text DEFAULT 'pending', -- pending, approved, rejected, cancelled
  approved_by_id uuid REFERENCES users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  rejection_reason text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_leave_requests_org_id ON leave_requests(organization_id);
CREATE INDEX idx_leave_requests_user_id ON leave_requests(user_id);
CREATE INDEX idx_leave_requests_status ON leave_requests(status);
CREATE INDEX idx_leave_requests_dates ON leave_requests(start_date, end_date);

ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own leave requests"
  ON leave_requests FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = leave_requests.organization_id
      AND (u.id = user_id OR u.role IN ('owner', 'admin', 'manager'))
    )
  );

CREATE POLICY "Users can create own leave requests"
  ON leave_requests FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = organization_id
      AND u.id = user_id
    )
  );

CREATE POLICY "Managers can approve leave requests"
  ON leave_requests FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = leave_requests.organization_id
      AND u.role IN ('owner', 'admin', 'manager')
    )
  );

-- Employee Skills: Skills and competencies
CREATE TABLE IF NOT EXISTS employee_skills (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  skill_name text NOT NULL,
  proficiency_level text DEFAULT 'intermediate', -- beginner, intermediate, advanced, expert
  years_of_experience numeric(4,1),
  is_verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, user_id, skill_name)
);

CREATE INDEX idx_employee_skills_org_id ON employee_skills(organization_id);
CREATE INDEX idx_employee_skills_user_id ON employee_skills(user_id);
CREATE INDEX idx_employee_skills_skill_name ON employee_skills(skill_name);

ALTER TABLE employee_skills ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view skills in org"
  ON employee_skills FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = employee_skills.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage own skills"
  ON employee_skills FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = organization_id
      AND u.id = user_id
    )
  );

CREATE POLICY "Users can update own skills"
  ON employee_skills FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = employee_skills.organization_id
      AND u.id = user_id
    )
  );

-- Insert default leave types for new organizations
CREATE OR REPLACE FUNCTION create_default_leave_types()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO leave_types (organization_id, name, annual_quota, is_paid) VALUES
    (NEW.id, 'Casual Leave', 12, true),
    (NEW.id, 'Sick Leave', 10, true),
    (NEW.id, 'Annual Leave', 20, true),
    (NEW.id, 'Unpaid Leave', 0, false);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_create_default_leave_types
AFTER INSERT ON organizations
FOR EACH ROW EXECUTE FUNCTION create_default_leave_types();
