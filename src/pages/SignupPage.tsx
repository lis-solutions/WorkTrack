import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../services/auth';

const SignupPage: React.FC = () => {
  const [step, setStep] = useState<'org' | 'user'>('org');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  const [orgData, setOrgData] = useState({
    organizationName: '',
    organizationEmail: '',
    departmentName: 'General',
  });

  const [userData, setUserData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
  });

  const handleOrgSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!orgData.organizationName || !orgData.organizationEmail) {
      setError('Please fill in all fields');
      return;
    }

    setStep('user');
  };

  const handleUserSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (!userData.email || !userData.password || !userData.firstName || !userData.lastName) {
        setError('Please fill in all fields');
        setLoading(false);
        return;
      }

      if (userData.password !== userData.confirmPassword) {
        setError('Passwords do not match');
        setLoading(false);
        return;
      }

      if (userData.password.length < 8) {
        setError('Password must be at least 8 characters');
        setLoading(false);
        return;
      }

      await authService.createOrganizationAndUser(
        orgData.organizationName,
        orgData.organizationEmail,
        orgData.departmentName,
        userData.email,
        userData.firstName,
        userData.lastName
      );

      navigate('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 via-blue-500 to-purple-600 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="h-14 w-14 bg-white rounded-lg flex items-center justify-center mx-auto mb-4">
            <span className="text-2xl font-bold text-blue-600">W</span>
          </div>
          <h1 className="text-4xl font-bold text-white mb-2">WorkTrack</h1>
          <p className="text-blue-100">Create your account</p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-2xl shadow-2xl p-8">
          {/* Progress steps */}
          <div className="flex gap-2 mb-8">
            <div
              className={`h-1 flex-1 rounded-full transition ${
                step === 'org' || step === 'user' ? 'bg-blue-600' : 'bg-gray-300'
              }`}
            />
            <div className={`h-1 flex-1 rounded-full transition ${step === 'user' ? 'bg-blue-600' : 'bg-gray-300'}`} />
          </div>

          {error && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
              {error}
            </div>
          )}

          {step === 'org' ? (
            <form onSubmit={handleOrgSubmit} className="space-y-4">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">Create Your Organization</h2>

              <div>
                <label htmlFor="org-name" className="block text-sm font-medium text-gray-700 mb-1">
                  Organization Name
                </label>
                <input
                  id="org-name"
                  type="text"
                  value={orgData.organizationName}
                  onChange={(e) => setOrgData({ ...orgData, organizationName: e.target.value })}
                  placeholder="Acme Corporation"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                />
              </div>

              <div>
                <label htmlFor="org-email" className="block text-sm font-medium text-gray-700 mb-1">
                  Organization Email Domain
                </label>
                <input
                  id="org-email"
                  type="email"
                  value={orgData.organizationEmail}
                  onChange={(e) => setOrgData({ ...orgData, organizationEmail: e.target.value })}
                  placeholder="acme.com"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                />
              </div>

              <div>
                <label htmlFor="dept-name" className="block text-sm font-medium text-gray-700 mb-1">
                  Initial Department (optional)
                </label>
                <input
                  id="dept-name"
                  type="text"
                  value={orgData.departmentName}
                  onChange={(e) => setOrgData({ ...orgData, departmentName: e.target.value })}
                  placeholder="General"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                />
              </div>

              <button
                type="submit"
                className="w-full bg-blue-600 text-white font-medium py-2 rounded-lg hover:bg-blue-700 transition"
              >
                Continue
              </button>
            </form>
          ) : (
            <form onSubmit={handleUserSubmit} className="space-y-4">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">Create Your Account</h2>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label htmlFor="first-name" className="block text-sm font-medium text-gray-700 mb-1">
                    First Name
                  </label>
                  <input
                    id="first-name"
                    type="text"
                    value={userData.firstName}
                    onChange={(e) => setUserData({ ...userData, firstName: e.target.value })}
                    placeholder="John"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                  />
                </div>

                <div>
                  <label htmlFor="last-name" className="block text-sm font-medium text-gray-700 mb-1">
                    Last Name
                  </label>
                  <input
                    id="last-name"
                    type="text"
                    value={userData.lastName}
                    onChange={(e) => setUserData({ ...userData, lastName: e.target.value })}
                    placeholder="Doe"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                  Email Address
                </label>
                <input
                  id="email"
                  type="email"
                  value={userData.email}
                  onChange={(e) => setUserData({ ...userData, email: e.target.value })}
                  placeholder="john@acme.com"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                />
              </div>

              <div>
                <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                  Password
                </label>
                <input
                  id="password"
                  type="password"
                  value={userData.password}
                  onChange={(e) => setUserData({ ...userData, password: e.target.value })}
                  placeholder="••••••••"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                />
              </div>

              <div>
                <label htmlFor="confirm-password" className="block text-sm font-medium text-gray-700 mb-1">
                  Confirm Password
                </label>
                <input
                  id="confirm-password"
                  type="password"
                  value={userData.confirmPassword}
                  onChange={(e) => setUserData({ ...userData, confirmPassword: e.target.value })}
                  placeholder="••••••••"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
                />
              </div>

              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setStep('org')}
                  className="flex-1 bg-gray-100 text-gray-700 font-medium py-2 rounded-lg hover:bg-gray-200 transition"
                >
                  Back
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="flex-1 bg-blue-600 text-white font-medium py-2 rounded-lg hover:bg-blue-700 transition disabled:opacity-50"
                >
                  {loading ? 'Creating...' : 'Create Account'}
                </button>
              </div>
            </form>
          )}

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <button onClick={() => navigate('/login')} className="text-blue-600 hover:text-blue-700 font-medium">
                Sign in
              </button>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SignupPage;
