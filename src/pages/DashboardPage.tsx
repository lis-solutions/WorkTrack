import React, { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { Task, Timesheet } from '../types';
import { CheckCircle2, Clock, AlertCircle, TrendingUp } from 'lucide-react';

const DashboardPage: React.FC = () => {
  const { worktrackUser } = useAuth();
  const [tasks, setTasks] = useState<Task[]>([]);
  const [timesheets, setTimesheets] = useState<Timesheet[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      if (!worktrackUser) return;

      try {
        const { data: tasksData, error: tasksError } = await supabase
          .from('tasks')
          .select('*')
          .eq('organization_id', worktrackUser.organization_id)
          .or(`assigned_to_id.eq.${worktrackUser.id},created_by_id.eq.${worktrackUser.id}`)
          .order('created_at', { ascending: false })
          .limit(5);

        if (tasksError) throw tasksError;
        setTasks(tasksData || []);

        const { data: timesheetData, error: timesheetError } = await supabase
          .from('timesheets')
          .select('*')
          .eq('organization_id', worktrackUser.organization_id)
          .eq('user_id', worktrackUser.id)
          .order('entry_date', { ascending: false })
          .limit(7);

        if (timesheetError) throw timesheetError;
        setTimesheets(timesheetData || []);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, [worktrackUser]);

  const taskStats = {
    total: tasks.length,
    completed: tasks.filter((t) => t.status === 'done').length,
    inProgress: tasks.filter((t) => t.status === 'in_progress').length,
    overdue: tasks.filter((t) => t.due_date && new Date(t.due_date) < new Date() && t.status !== 'done').length,
  };

  const totalHoursLogged = timesheets.reduce((acc, ts) => acc + (ts.hours_worked || 0), 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-gray-500">Loading dashboard...</div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Welcome, {worktrackUser?.first_name}!</h1>
        <p className="text-gray-600 mt-2">Here's your work overview for today</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <StatCard
          icon={CheckCircle2}
          label="Tasks Completed"
          value={taskStats.completed}
          total={taskStats.total}
          color="emerald"
        />
        <StatCard
          icon={Clock}
          label="In Progress"
          value={taskStats.inProgress}
          total={taskStats.total}
          color="blue"
        />
        <StatCard
          icon={AlertCircle}
          label="Overdue Tasks"
          value={taskStats.overdue}
          total={taskStats.total}
          color="red"
        />
        <StatCard
          icon={TrendingUp}
          label="Hours Logged"
          value={totalHoursLogged.toFixed(1)}
          total="this week"
          color="purple"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Tasks */}
        <div className="lg:col-span-2 bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">Recent Tasks</h2>
          </div>

          <div className="divide-y divide-gray-200">
            {tasks.length === 0 ? (
              <div className="p-6 text-center text-gray-500">No tasks yet</div>
            ) : (
              tasks.map((task) => (
                <div key={task.id} className="p-4 hover:bg-gray-50 transition">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <h3 className="font-medium text-gray-900">{task.title}</h3>
                      <p className="text-sm text-gray-500 mt-1">{task.description}</p>
                    </div>
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-medium ${
                        task.status === 'done'
                          ? 'bg-emerald-100 text-emerald-700'
                          : task.status === 'in_progress'
                            ? 'bg-blue-100 text-blue-700'
                            : 'bg-gray-100 text-gray-700'
                      }`}
                    >
                      {task.status}
                    </span>
                  </div>

                  {task.due_date && (
                    <div className="mt-2 text-xs text-gray-500">
                      Due: {new Date(task.due_date).toLocaleDateString()}
                    </div>
                  )}
                </div>
              ))
            )}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="space-y-6">
          <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg p-6 text-white">
            <h3 className="font-semibold mb-4">Quick Actions</h3>
            <div className="space-y-2">
              <button className="w-full bg-white/20 hover:bg-white/30 text-white font-medium py-2 px-4 rounded-lg transition">
                Create Task
              </button>
              <button className="w-full bg-white/20 hover:bg-white/30 text-white font-medium py-2 px-4 rounded-lg transition">
                Log Time
              </button>
              <button className="w-full bg-white/20 hover:bg-white/30 text-white font-medium py-2 px-4 rounded-lg transition">
                Check In
              </button>
            </div>
          </div>

          {/* Hours This Week */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <h3 className="font-semibold text-gray-900 mb-4">Hours This Week</h3>
            <div className="space-y-3">
              {timesheets.slice(0, 3).map((ts) => (
                <div key={ts.id} className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">
                    {new Date(ts.entry_date).toLocaleDateString('en-US', { weekday: 'short' })}
                  </span>
                  <span className="font-medium text-gray-900">{ts.hours_worked}h</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

interface StatCardProps {
  icon: React.ElementType;
  label: string;
  value: number | string;
  total: number | string;
  color: string;
}

const StatCard: React.FC<StatCardProps> = ({ icon: Icon, label, value, total, color }) => {
  const colorClasses: Record<string, string> = {
    emerald: 'bg-emerald-50 text-emerald-600',
    blue: 'bg-blue-50 text-blue-600',
    red: 'bg-red-50 text-red-600',
    purple: 'bg-purple-50 text-purple-600',
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <div className={`inline-flex p-3 rounded-lg ${colorClasses[color] || colorClasses.blue}`}>
        <Icon size={24} />
      </div>
      <p className="text-sm text-gray-600 mt-4">{label}</p>
      <p className="text-3xl font-bold text-gray-900 mt-1">
        {value}
        {typeof total === 'number' && <span className="text-lg text-gray-500">/{total}</span>}
      </p>
      {typeof total === 'string' && <p className="text-xs text-gray-500 mt-2">{total}</p>}
    </div>
  );
};

export default DashboardPage;
