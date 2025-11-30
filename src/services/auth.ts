import { supabase } from '../lib/supabase';
import { User } from '../types';

export const authService = {
  async signUp(email: string, password: string, firstName: string, lastName: string) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          first_name: firstName,
          last_name: lastName,
        },
      },
    });

    if (error) throw error;
    return data;
  },

  async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;
    return data;
  },

  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  },

  async resetPassword(email: string) {
    const { error } = await supabase.auth.resetPasswordForEmail(email);
    if (error) throw error;
  },

  async updatePassword(newPassword: string) {
    const { error } = await supabase.auth.updateUser({
      password: newPassword,
    });

    if (error) throw error;
  },

  async createOrganizationAndUser(
    organizationName: string,
    organizationEmail: string,
    departmentName: string,
    userEmail: string,
    firstName: string,
    lastName: string
  ) {
    const { data: orgData, error: orgError } = await supabase
      .from('organizations')
      .insert([
        {
          name: organizationName,
          email_domain: organizationEmail,
          type: 'startup',
        },
      ])
      .select()
      .single();

    if (orgError) throw orgError;

    const { data: deptData, error: deptError } = await supabase
      .from('departments')
      .insert([
        {
          organization_id: orgData.id,
          name: departmentName,
        },
      ])
      .select()
      .single();

    if (deptError) throw deptError;

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: userEmail,
      password: Math.random().toString(36).substring(2, 15),
      options: {
        data: {
          first_name: firstName,
          last_name: lastName,
        },
      },
    });

    if (authError) throw authError;

    const { data: userData, error: userError } = await supabase
      .from('users')
      .insert([
        {
          organization_id: orgData.id,
          department_id: deptData.id,
          auth_user_id: authData.user!.id,
          email: userEmail,
          first_name: firstName,
          last_name: lastName,
          role: 'owner',
          is_verified: true,
        },
      ])
      .select()
      .single();

    if (userError) throw userError;

    const { error: licenseError } = await supabase
      .from('licenses')
      .insert([
        {
          organization_id: orgData.id,
          plan_name: 'starter',
          license_key: `lic-${orgData.id.substring(0, 8)}-${Date.now()}`,
          status: 'active',
          max_users: 50,
          max_storage_gb: 100,
          features: ['task_management', 'timesheet', 'chat'],
        },
      ]);

    if (licenseError) throw licenseError;

    return { organization: orgData, department: deptData, user: userData, auth: authData };
  },

  async addUserToOrganization(
    organizationId: string,
    departmentId: string,
    email: string,
    firstName: string,
    lastName: string,
    role: string = 'employee'
  ) {
    const tempPassword = Math.random().toString(36).substring(2, 15);

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password: tempPassword,
      options: {
        data: {
          first_name: firstName,
          last_name: lastName,
        },
      },
    });

    if (authError) throw authError;

    const { data: userData, error: userError } = await supabase
      .from('users')
      .insert([
        {
          organization_id: organizationId,
          department_id: departmentId,
          auth_user_id: authData.user!.id,
          email,
          first_name: firstName,
          last_name: lastName,
          role,
        },
      ])
      .select()
      .single();

    if (userError) throw userError;

    return { user: userData as User, auth: authData, tempPassword };
  },

  async getCurrentUser() {
    const {
      data: { session },
      error,
    } = await supabase.auth.getSession();

    if (error) throw error;
    return session?.user || null;
  },
};
