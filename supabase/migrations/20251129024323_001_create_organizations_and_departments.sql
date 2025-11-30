/*
  # Create Organizations and Departments Tables
  
  Foundation tables for multi-tenant architecture without circular dependencies.
*/

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Organizations: Root tenant entities
CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type text NOT NULL DEFAULT 'startup',
  email_domain text UNIQUE,
  config jsonb DEFAULT '{}',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organizations are viewable by authenticated users"
  ON organizations FOR SELECT
  TO authenticated
  USING (true);

-- Departments: Logical groupings within organizations
CREATE TABLE IF NOT EXISTS departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  parent_department_id uuid REFERENCES departments(id) ON DELETE SET NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_departments_org_id ON departments(organization_id);
CREATE INDEX idx_departments_parent_id ON departments(parent_department_id);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

-- Roles: RBAC definitions per organization
CREATE TABLE IF NOT EXISTS roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  permissions jsonb DEFAULT '[]',
  hierarchy_level integer DEFAULT 0,
  is_custom boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, name)
);

CREATE INDEX idx_roles_org_id ON roles(organization_id);

ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- Create default roles for each organization
CREATE OR REPLACE FUNCTION create_default_roles()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO roles (organization_id, name, hierarchy_level, permissions) VALUES
    (NEW.id, 'Owner', 3, '["*"]'::jsonb),
    (NEW.id, 'Admin', 2, '["user:manage", "task:manage", "reports:view", "org:config"]'::jsonb),
    (NEW.id, 'Manager', 1, '["user:view:team", "task:manage:team", "reports:view:team"]'::jsonb),
    (NEW.id, 'Employee', 0, '["task:own", "timesheet:own", "chat:access"]'::jsonb);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_create_default_roles
AFTER INSERT ON organizations
FOR EACH ROW EXECUTE FUNCTION create_default_roles();

-- Create SuperAdmin organization
INSERT INTO organizations (id, name, type, config) 
VALUES (
  'f47ac10b-58cc-4372-a567-0e02b2c3d479'::uuid,
  'WorkTrack SuperAdmin',
  'internal',
  '{"is_superadmin": true}'::jsonb
)
ON CONFLICT DO NOTHING;
