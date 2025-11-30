import React, { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { Timesheet } from '../types';

const TimesheetPage: React.FC = () => {
  const { worktrackUser } = useAuth();
  const [timesheets, setTimesheets] = useState<Timesheet[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchTimesheets = async () => {
      if (!worktrackUser) return;

      try {
        const { data, error } = await supabase
          .from('timesheets')
          .select('*')
          .eq('organization_id', worktrackUser.organization_id)
          .eq('user_id', worktrackUser.id)
          .order('entry_date', { ascending: false });

        if (error) throw error;
        setTimesheets(data || []);
      } finally {
        setLoading(false);
      }
    };

    fetchTimesheets();
  }, [worktrackUser]);

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      draft: 'bg-gray-100 text-gray-700',
      submitted: 'bg-blue-100 text-blue-700',
      approved: 'bg-emerald-100 text-emerald-700',
      rejected: 'bg-red-100 text-red-700',
    };
    return colors[status] || colors.draft;
  };

  const totalHours = timesheets.reduce((acc, ts) => acc + (ts.hours_worked || 0), 0);

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Timesheet</h1>
        <p className="text-gray-600 mt-2">Track your daily work hours</p>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <p className="text-sm text-gray-600">Total Hours</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{totalHours.toFixed(1)}h</p>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <p className="text-sm text-gray-600">Approved</p>
          <p className="text-3xl font-bold text-emerald-600 mt-2">
            {timesheets.filter((t) => t.status === 'approved').length}
          </p>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <p className="text-sm text-gray-600">Pending</p>
          <p className="text-3xl font-bold text-blue-600 mt-2">
            {timesheets.filter((t) => t.status === 'submitted' || t.status === 'draft').length}
          </p>
        </div>
      </div>

      {/* Timesheets Table */}
      {loading ? (
        <div className="text-center text-gray-500 py-12">Loading timesheets...</div>
      ) : timesheets.length === 0 ? (
        <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
          <p className="text-gray-500">No timesheet entries yet</p>
          <button className="mt-4 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition">
            Add Entry
          </button>
        </div>
      ) : (
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Date</th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Hours Worked</th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Status</th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Notes</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {timesheets.map((ts) => (
                <tr key={ts.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 text-sm text-gray-900">
                    {new Date(ts.entry_date).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{ts.hours_worked}h</td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(ts.status)}`}>
                      {ts.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">{ts.notes || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default TimesheetPage;
