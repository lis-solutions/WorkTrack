import React from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  CheckSquare,
  Clock,
  Users,
  MessageSquare,
  Settings,
  LogOut,
  Menu,
  X,
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useState } from 'react';

const Sidebar: React.FC = () => {
  const { worktrackUser } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [isOpen, setIsOpen] = useState(false);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    navigate('/login');
  };

  const isSuperAdmin = worktrackUser?.role === 'superadmin';

  const menuItems = [
    {
      label: 'Dashboard',
      icon: LayoutDashboard,
      path: '/dashboard',
      roles: ['owner', 'admin', 'manager', 'employee'],
    },
    {
      label: 'Tasks',
      icon: CheckSquare,
      path: '/tasks',
      roles: ['owner', 'admin', 'manager', 'employee'],
    },
    {
      label: 'Timesheet',
      icon: Clock,
      path: '/timesheet',
      roles: ['owner', 'admin', 'manager', 'employee'],
    },
    {
      label: 'Team',
      icon: Users,
      path: '/team',
      roles: ['owner', 'admin', 'manager'],
    },
    {
      label: 'Messages',
      icon: MessageSquare,
      path: '/messages',
      roles: ['owner', 'admin', 'manager', 'employee'],
    },
    {
      label: 'Settings',
      icon: Settings,
      path: '/settings',
      roles: ['owner', 'admin'],
    },
  ];

  const adminItems = [
    {
      label: 'SuperAdmin',
      icon: Settings,
      path: '/superadmin',
      roles: ['superadmin'],
    },
  ];

  const visibleItems = isSuperAdmin
    ? adminItems
    : menuItems.filter((item) => item.roles.includes(worktrackUser?.role || 'employee'));

  return (
    <>
      {/* Mobile toggle */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-md bg-white shadow-md"
      >
        {isOpen ? <X size={24} /> : <Menu size={24} />}
      </button>

      {/* Sidebar */}
      <aside
        className={`${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        } lg:translate-x-0 fixed lg:static top-0 left-0 h-screen w-64 bg-white border-r border-gray-200 transition-transform duration-300 z-40 flex flex-col`}
      >
        {/* Logo */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 bg-blue-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-lg">W</span>
            </div>
            <h1 className="text-xl font-bold text-gray-900">WorkTrack</h1>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 overflow-y-auto">
          <div className="space-y-2">
            {visibleItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;

              return (
                <button
                  key={item.path}
                  onClick={() => {
                    navigate(item.path);
                    setIsOpen(false);
                  }}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                    isActive
                      ? 'bg-blue-50 text-blue-600 font-medium'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <Icon size={20} />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </div>
        </nav>

        {/* User section */}
        <div className="p-4 border-t border-gray-200">
          <div className="flex items-center gap-3 mb-4 px-2">
            {worktrackUser?.avatar_url ? (
              <img
                src={worktrackUser.avatar_url}
                alt={worktrackUser.first_name}
                className="h-10 w-10 rounded-full object-cover"
              />
            ) : (
              <div className="h-10 w-10 bg-gray-300 rounded-full flex items-center justify-center text-sm font-semibold text-white">
                {(worktrackUser?.first_name?.[0] || 'U').toUpperCase()}
              </div>
            )}
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">
                {worktrackUser?.first_name} {worktrackUser?.last_name}
              </p>
              <p className="text-xs text-gray-500 truncate capitalize">{worktrackUser?.role}</p>
            </div>
          </div>

          <button
            onClick={handleSignOut}
            className="w-full flex items-center gap-3 px-4 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <LogOut size={18} />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* Mobile overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 lg:hidden z-30"
          onClick={() => setIsOpen(false)}
        />
      )}
    </>
  );
};

export default Sidebar;
