import React from 'react';
import { useAuth } from '../context/AuthContext';
import { Bell, Search } from 'lucide-react';

const TopNav: React.FC = () => {
  const { organization } = useAuth();

  return (
    <header className="sticky top-0 z-10 bg-white border-b border-gray-200">
      <div className="px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-4 flex-1">
          <div className="hidden md:flex items-center gap-2 bg-gray-100 px-4 py-2 rounded-lg max-w-md">
            <Search size={18} className="text-gray-500" />
            <input
              type="text"
              placeholder="Search..."
              className="bg-transparent outline-none text-sm w-full"
            />
          </div>
        </div>

        <div className="flex items-center gap-4">
          {organization && (
            <div className="text-right hidden sm:block">
              <p className="text-sm font-medium text-gray-900">{organization.name}</p>
              <p className="text-xs text-gray-500 capitalize">{organization.type} plan</p>
            </div>
          )}

          <button className="relative p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors">
            <Bell size={20} />
            <span className="absolute top-1 right-1 h-2 w-2 bg-red-600 rounded-full"></span>
          </button>
        </div>
      </div>
    </header>
  );
};

export default TopNav;
