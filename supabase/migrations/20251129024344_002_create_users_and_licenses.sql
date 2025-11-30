/*
  # Create Users, Licenses, and Activity Logs Tables

  Second phase: Add user management, subscription system, and audit trails.
  Includes comprehensive RLS policies for multi-tenant data isolation.
*/

-- Users: Employees with role assignments
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  department_id uuid NOT NULL REFERENCES departments(id) ON DELETE RESTRICT,
  auth_user_id uuid NOT NULL,
  email text NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  role text NOT NULL DEFAULT 'employee',
  role_id uuid REFERENCES roles(id) ON DELETE SET NULL,
  phone text,
  avatar_url text,
  is_active boolean DEFAULT true,
  is_verified boolean DEFAULT false,
  last_login timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, email),
  UNIQUE(auth_user_id, organization_id)
);

CREATE INDEX idx_users_org_id ON users(organization_id);
CREATE INDEX idx_users_dept_id ON users(department_id);
CREATE INDEX idx_users_auth_id ON users(auth_user_id);
CREATE INDEX idx_users_role ON users(role);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can read organization members"
  ON users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = users.organization_id
    )
  );

CREATE POLICY "Admins can insert users"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = organization_id
      AND u.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = auth_user_id)
  WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Admins can update organization users"
  ON users FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_user_id = auth.uid()
      AND u.organization_id = users.organization_id
      AND u.role IN ('owner', 'admin')
    )
  );

-- RLS policies for departments (now that users table exists)
CREATE POLICY "Users can view departments in their organization"
  ON departments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = departments.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can create departments"
  ON departments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = organization_id
      AND users.auth_user_id = auth.uid()
      AND users.role IN ('owner', 'admin')
    )
  );

-- RLS policies for roles (now that users table exists)
CREATE POLICY "Users can view roles in their organization"
  ON roles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = roles.organization_id
      AND users.auth_user_id = auth.uid()
    )
  );

-- Licenses: Subscription and feature management
CREATE TABLE IF NOT EXISTS licenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL UNIQUE REFERENCES organizations(id) ON DELETE CASCADE,
  plan_name text NOT NULL DEFAULT 'starter',
  license_key text UNIQUE NOT NULL,
  status text NOT NULL DEFAULT 'active',
  max_users integer DEFAULT 50,
  max_storage_gb integer DEFAULT 100,
  features jsonb DEFAULT '[]',
  start_date timestamptz DEFAULT now(),
  expiry_date timestamptz,
  auto_renew boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_licenses_org_id ON licenses(organization_id);
CREATE INDEX idx_licenses_status ON licenses(status);

ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organization admins can view own license"
  ON licenses FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = licenses.organization_id
      AND users.auth_user_id = auth.uid()
      AND users.role IN ('owner', 'admin')
    )
  );

-- Activity Logs: Audit trail for compliance
CREATE TABLE IF NOT EXISTS activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  action text NOT NULL,
  resource_type text NOT NULL,
  resource_id uuid,
  changes jsonb DEFAULT '{}',
  ip_address text,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_activity_logs_org_id ON activity_logs(organization_id);
CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at DESC);
CREATE INDEX idx_activity_logs_resource ON activity_logs(resource_type, resource_id);

ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own organization activity logs"
  ON activity_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = activity_logs.organization_id
      AND users.auth_user_id = auth.uid()
      AND users.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Admins can insert activity logs"
  ON activity_logs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.organization_id = activity_logs.organization_id
      AND users.auth_user_id = auth.uid()
      AND users.role IN ('owner', 'admin')
    )
  );
