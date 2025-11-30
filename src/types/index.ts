export interface Organization {
  id: string;
  name: string;
  type: string;
  email_domain?: string;
  config: Record<string, unknown>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Department {
  id: string;
  organization_id: string;
  name: string;
  description?: string;
  parent_department_id?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Role {
  id: string;
  organization_id: string;
  name: string;
  description?: string;
  permissions: string[];
  hierarchy_level: number;
  is_custom: boolean;
  created_at: string;
  updated_at: string;
}

export interface User {
  id: string;
  organization_id: string;
  department_id: string;
  auth_user_id: string;
  email: string;
  first_name: string;
  last_name: string;
  role: string;
  role_id?: string;
  phone?: string;
  avatar_url?: string;
  is_active: boolean;
  is_verified: boolean;
  last_login?: string;
  created_at: string;
  updated_at: string;
}

export interface Task {
  id: string;
  organization_id: string;
  created_by_id: string;
  assigned_to_id?: string;
  title: string;
  description?: string;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'todo' | 'in_progress' | 'review' | 'done' | 'cancelled';
  due_date?: string;
  estimated_hours?: number;
  actual_hours: number;
  completion_percentage: number;
  tags: string[];
  attachments: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Timesheet {
  id: string;
  organization_id: string;
  user_id: string;
  entry_date: string;
  hours_worked: number;
  status: 'draft' | 'submitted' | 'approved' | 'rejected';
  notes?: string;
  approved_by_id?: string;
  approved_at?: string;
  created_at: string;
  updated_at: string;
}

export interface Attendance {
  id: string;
  organization_id: string;
  user_id: string;
  check_in_time: string;
  check_out_time?: string;
  hours_present?: number;
  location?: string;
  device_info?: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface Notification {
  id: string;
  organization_id: string;
  recipient_id: string;
  actor_id?: string;
  notification_type: string;
  resource_type?: string;
  resource_id?: string;
  title: string;
  message?: string;
  action_url?: string;
  is_read: boolean;
  read_at?: string;
  created_at: string;
}

export interface ChatChannel {
  id: string;
  organization_id: string;
  name: string;
  description?: string;
  channel_type: 'general' | 'task' | 'department' | 'direct';
  task_id?: string;
  department_id?: string;
  is_active: boolean;
  created_by_id: string;
  created_at: string;
  updated_at: string;
}

export interface ChatMessage {
  id: string;
  organization_id: string;
  channel_id: string;
  user_id: string;
  message: string;
  attachments: string[];
  edited_at?: string;
  is_deleted: boolean;
  created_at: string;
}

export interface License {
  id: string;
  organization_id: string;
  plan_name: string;
  license_key: string;
  status: 'active' | 'expired' | 'suspended' | 'cancelled';
  max_users: number;
  max_storage_gb: number;
  features: string[];
  start_date: string;
  expiry_date?: string;
  auto_renew: boolean;
  created_at: string;
  updated_at: string;
}

export interface AuthUser {
  id: string;
  email: string;
  app_metadata?: Record<string, unknown>;
  user_metadata?: Record<string, unknown>;
  created_at: string;
}

export interface AuthState {
  user: AuthUser | null;
  loading: boolean;
  error: string | null;
}

export interface CurrentUserContext {
  authUser: AuthUser | null;
  worktrackUser: User | null;
  organization: Organization | null;
  loading: boolean;
  error: string | null;
}
