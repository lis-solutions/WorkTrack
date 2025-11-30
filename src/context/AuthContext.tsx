import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { supabase } from '../lib/supabase';
import { AuthUser, CurrentUserContext, User, Organization } from '../types';

const AuthContext = createContext<CurrentUserContext | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);
  const [worktrackUser, setWorktrackUser] = useState<User | null>(null);
  const [organization, setOrganization] = useState<Organization | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const { data, error: authError } = await supabase.auth.getSession();

        if (authError) {
          setError(authError.message);
          setLoading(false);
          return;
        }

        if (data.session?.user) {
          const authUserData = data.session.user as unknown as AuthUser;
          setAuthUser(authUserData);

          const { data: userData, error: userError } = await supabase
            .from('users')
            .select('*')
            .eq('auth_user_id', authUserData.id)
            .maybeSingle();

          if (userError) {
            setError(userError.message);
          } else if (userData) {
            setWorktrackUser(userData);

            const { data: orgData, error: orgError } = await supabase
              .from('organizations')
              .select('*')
              .eq('id', userData.organization_id)
              .maybeSingle();

            if (orgError) {
              setError(orgError.message);
            } else if (orgData) {
              setOrganization(orgData);
            }
          }
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred');
      } finally {
        setLoading(false);
      }
    })();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        if (session?.user) {
          const authUserData = session.user as unknown as AuthUser;
          setAuthUser(authUserData);

          const { data: userData } = await supabase
            .from('users')
            .select('*')
            .eq('auth_user_id', authUserData.id)
            .maybeSingle();

          if (userData) {
            setWorktrackUser(userData);

            const { data: orgData } = await supabase
              .from('organizations')
              .select('*')
              .eq('id', userData.organization_id)
              .maybeSingle();

            if (orgData) {
              setOrganization(orgData);
            }
          }
        } else {
          setAuthUser(null);
          setWorktrackUser(null);
          setOrganization(null);
        }
      }
    );

    return () => {
      subscription?.unsubscribe();
    };
  }, []);

  return (
    <AuthContext.Provider value={{ authUser, worktrackUser, organization, loading, error }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
