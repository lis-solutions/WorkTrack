import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import DashboardPage from './pages/DashboardPage';
import TasksPage from './pages/TasksPage';
import TimesheetPage from './pages/TimesheetPage';
import TeamPage from './pages/TeamPage';
import MessagesPage from './pages/MessagesPage';
import SettingsPage from './pages/SettingsPage';
import SuperAdminPage from './pages/SuperAdminPage';

function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/signup" element={<SignupPage />} />

          <Route
            path="/dashboard"
            element={
              <Layout>
                <DashboardPage />
              </Layout>
            }
          />

          <Route
            path="/tasks"
            element={
              <Layout>
                <TasksPage />
              </Layout>
            }
          />

          <Route
            path="/timesheet"
            element={
              <Layout>
                <TimesheetPage />
              </Layout>
            }
          />

          <Route
            path="/team"
            element={
              <Layout>
                <TeamPage />
              </Layout>
            }
          />

          <Route
            path="/messages"
            element={
              <Layout>
                <MessagesPage />
              </Layout>
            }
          />

          <Route
            path="/settings"
            element={
              <Layout>
                <SettingsPage />
              </Layout>
            }
          />

          <Route
            path="/superadmin"
            element={
              <Layout>
                <SuperAdminPage />
              </Layout>
            }
          />

          <Route path="/" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </AuthProvider>
    </Router>
  );
}

export default App;
