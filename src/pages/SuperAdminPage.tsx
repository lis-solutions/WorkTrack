import React from 'react';

const SuperAdminPage: React.FC = () => {
  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold text-gray-900">SuperAdmin Console</h1>
      <p className="text-gray-600 mt-2">Platform administration and monitoring</p>

      <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h3 className="font-semibold text-gray-900">Active Organizations</h3>
          <p className="text-3xl font-bold text-blue-600 mt-4">0</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h3 className="font-semibold text-gray-900">Total Users</h3>
          <p className="text-3xl font-bold text-emerald-600 mt-4">0</p>
        </div>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h3 className="font-semibold text-gray-900">Active Licenses</h3>
          <p className="text-3xl font-bold text-purple-600 mt-4">0</p>
        </div>
      </div>

      <div className="mt-8 bg-white rounded-lg border border-gray-200 p-12 text-center">
        <p className="text-gray-500">SuperAdmin features coming soon</p>
      </div>
    </div>
  );
};

export default SuperAdminPage;
