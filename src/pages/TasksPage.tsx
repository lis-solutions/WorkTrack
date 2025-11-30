import React, { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { Task } from '../types';
import { Plus, Filter } from 'lucide-react';

const TasksPage: React.FC = () => {
  const { worktrackUser } = useAuth();
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'assigned' | 'created'>('all');

  useEffect(() => {
    const fetchTasks = async () => {
      if (!worktrackUser) return;

      try {
        let query = supabase
          .from('tasks')
          .select('*')
          .eq('organization_id', worktrackUser.organization_id);

        if (filter === 'assigned') {
          query = query.eq('assigned_to_id', worktrackUser.id);
        } else if (filter === 'created') {
          query = query.eq('created_by_id', worktrackUser.id);
        }

        const { data, error } = await query.order('created_at', { ascending: false });

        if (error) throw error;
        setTasks(data || []);
      } finally {
        setLoading(false);
      }
    };

    fetchTasks();
  }, [worktrackUser, filter]);

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      todo: 'bg-gray-100 text-gray-700',
      in_progress: 'bg-blue-100 text-blue-700',
      review: 'bg-purple-100 text-purple-700',
      done: 'bg-emerald-100 text-emerald-700',
      cancelled: 'bg-red-100 text-red-700',
    };
    return colors[status] || colors.todo;
  };

  const getPriorityColor = (priority: string) => {
    const colors: Record<string, string> = {
      low: 'text-gray-500',
      medium: 'text-yellow-500',
      high: 'text-orange-500',
      urgent: 'text-red-500',
    };
    return colors[priority] || colors.medium;
  };

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Tasks</h1>
          <p className="text-gray-600 mt-2">Manage and track your work items</p>
        </div>
        <button className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition">
          <Plus size={20} />
          New Task
        </button>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4 mb-6">
        <Filter size={20} className="text-gray-400" />
        <div className="flex gap-2">
          {(['all', 'assigned', 'created'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-lg capitalize transition ${
                filter === f
                  ? 'bg-blue-600 text-white'
                  : 'bg-white border border-gray-200 text-gray-700 hover:border-gray-300'
              }`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* Tasks List */}
      {loading ? (
        <div className="text-center text-gray-500 py-12">Loading tasks...</div>
      ) : tasks.length === 0 ? (
        <div className="text-center text-gray-500 py-12">No tasks found</div>
      ) : (
        <div className="grid gap-4">
          {tasks.map((task) => (
            <div
              key={task.id}
              className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition cursor-pointer"
            >
              <div className="flex items-start justify-between gap-4 mb-4">
                <div className="flex-1">
                  <h3 className="text-lg font-semibold text-gray-900">{task.title}</h3>
                  <p className="text-gray-600 text-sm mt-1">{task.description}</p>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(task.status)}`}>
                  {task.status}
                </span>
              </div>

              <div className="flex items-center justify-between flex-wrap gap-4">
                <div className="flex items-center gap-6">
                  <div className="text-sm">
                    <p className="text-gray-500">Priority</p>
                    <p className={`font-medium capitalize ${getPriorityColor(task.priority)}`}>{task.priority}</p>
                  </div>

                  {task.due_date && (
                    <div className="text-sm">
                      <p className="text-gray-500">Due</p>
                      <p className="font-medium text-gray-900">
                        {new Date(task.due_date).toLocaleDateString()}
                      </p>
                    </div>
                  )}

                  {task.estimated_hours && (
                    <div className="text-sm">
                      <p className="text-gray-500">Est. Hours</p>
                      <p className="font-medium text-gray-900">{task.estimated_hours}h</p>
                    </div>
                  )}
                </div>

                <div className="w-24 bg-gray-200 rounded-full h-2">
                  <div
                    className="bg-blue-600 h-2 rounded-full"
                    style={{ width: `${task.completion_percentage}%` }}
                  />
                </div>
                <span className="text-sm font-medium text-gray-600">{task.completion_percentage}%</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default TasksPage;
