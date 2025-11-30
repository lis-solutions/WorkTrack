# WorkTrack - Enterprise Work Management Platform

## Quick Start

### Prerequisites
- Node.js 18+
- npm or yarn
- Supabase account (already configured)

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Open http://localhost:5173 in your browser
```

### Test Account

The system is ready for you to create your first account:

1. Visit http://localhost:5173/signup
2. Create an organization (e.g., "Acme Corp")
3. Create your account
4. You'll be automatically logged in to the dashboard

---

## Project Structure

```
src/
├── components/          # Reusable React components
│   ├── Layout.tsx      # Main app wrapper
│   ├── Sidebar.tsx     # Navigation
│   └── TopNav.tsx      # Header
├── context/            # React Context (Auth state)
├── lib/                # Utilities & Supabase client
├── pages/              # Page components (one per route)
├── services/           # Business logic (Auth, API calls)
├── types/              # TypeScript type definitions
├── App.tsx             # Router configuration
└── main.tsx            # Entry point
```

---

## Features Implemented

### Phase 0: Foundation ✓

**Database (Supabase PostgreSQL)**
- 24 tables with complete relational schema
- Row Level Security (RLS) for multi-tenant isolation
- Automatic audit trails and logging
- Support for all core business entities

**Frontend (React + TypeScript)**
- Authentication system (sign-up, sign-in, sign-out)
- Multi-role support (Owner, Admin, Manager, Employee)
- Organization onboarding
- Dashboard with analytics
- Task management UI
- Timesheet tracking UI
- Mobile-responsive design
- Beautiful, professional UI with Tailwind CSS

### Phase 1: MVP (In Development)

**Priority Features**
- [ ] Complete task CRUD operations
- [ ] Real-time task updates
- [ ] Timesheet approval workflow
- [ ] Team member management
- [ ] Chat/messaging system
- [ ] Notifications with real-time updates

---

## Database Overview

### Core Tables

| Table | Purpose |
|-------|---------|
| `organizations` | Tenant/company data |
| `departments` | Org structure |
| `roles` | RBAC permissions |
| `users` | Employee records |
| `licenses` | Subscription management |
| `tasks` | Work items |
| `timesheets` | Time tracking |
| `attendance` | Check-in/out |
| `chat_channels` | Messaging |
| `notifications` | Alerts & notifications |

**Security:** All tables enforce `organization_id` isolation via RLS policies.

---

## Key Concepts

### Multi-Tenancy

WorkTrack is built from the ground up for multiple organizations (tenants):

- Each organization has complete data isolation
- Users belong to one organization
- All queries automatically filter by organization_id via RLS
- Row Level Security policies prevent cross-org data access

### Authentication

- Built on Supabase Auth (JWT tokens)
- Email + password authentication
- Session persists across browser refreshes
- Automatic redirect to login if not authenticated

### Authorization (RBAC)

- **Owner**: Full access to organization
- **Admin**: Manage users, settings, reports
- **Manager**: View team, approve timesheets
- **Employee**: Personal tasks, timesheets, chat

---

## API Endpoints (Via Supabase)

The app uses Supabase directly (no custom API backend yet):

```typescript
// Example: Fetching tasks
const { data, error } = await supabase
  .from('tasks')
  .select('*')
  .eq('organization_id', orgId)
  .order('created_at', { ascending: false });
```

All queries are automatically filtered by RLS policies.

---

## Development Workflow

### Adding a New Feature

1. **Database (if needed)**
   - Create migration in Supabase dashboard
   - Update TypeScript types in `src/types/index.ts`

2. **Service Layer** (`src/services/`)
   - Add business logic
   - Handle Supabase queries

3. **Page/Component**
   - Create component in `src/pages/` or `src/components/`
   - Use context for auth data
   - Import service and types

4. **Routing**
   - Add route in `src/App.tsx`
   - Wrap in `<Layout>` for protected pages

5. **Test**
   - Test locally: `npm run dev`
   - Check build: `npm run build`

### Example: Adding a Task Feature

```typescript
// 1. Check types (src/types/index.ts)
interface Task {
  id: string;
  organization_id: string;
  title: string;
  status: 'todo' | 'in_progress' | 'done';
  // ...
}

// 2. Add service (src/services/tasks.ts)
export const taskService = {
  async createTask(data: Partial<Task>) {
    const { data: task, error } = await supabase
      .from('tasks')
      .insert([data])
      .select()
      .single();
    if (error) throw error;
    return task;
  }
};

// 3. Create component (src/pages/TasksPage.tsx)
import { taskService } from '../services/tasks';
// Fetch and display tasks...

// 4. Add to router (src/App.tsx)
<Route path="/tasks" element={<Layout><TasksPage /></Layout>} />
```

---

## Environment Variables

Located in `.env`:

```env
VITE_SUPABASE_URL=https://eofafslvtuivewjjessc.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Never commit `.env` to version control.

---

## Building & Deployment

### Development Build
```bash
npm run dev
```
Starts dev server at http://localhost:5173

### Production Build
```bash
npm run build
```
Creates optimized bundle in `dist/` folder

### Type Checking
```bash
npm run typecheck
```
Validate TypeScript without building

### Linting
```bash
npm run lint
```
Check code quality with ESLint

---

## Common Tasks

### Creating a New Page

1. Create file: `src/pages/MyPage.tsx`
2. Add to routing in `App.tsx`
3. Wrap in `<Layout>` for authentication

### Fetching Data

```typescript
import { supabase } from '../lib/supabase';

const { data, error } = await supabase
  .from('table_name')
  .select('*')
  .eq('organization_id', orgId);

if (error) throw error;
return data;
```

### Using Authentication

```typescript
import { useAuth } from '../context/AuthContext';

const MyComponent = () => {
  const { authUser, worktrackUser, organization } = useAuth();

  return <div>{worktrackUser?.first_name}</div>;
};
```

### Real-Time Subscriptions (Future)

```typescript
supabase
  .channel('tasks')
  .on('postgres_changes',
    { event: '*', schema: 'public', table: 'tasks' },
    (payload) => console.log('Change:', payload)
  )
  .subscribe();
```

---

## Troubleshooting

### "Cannot find module" errors
```bash
# Make sure dependencies are installed
npm install

# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### TypeScript errors
```bash
# Check types
npm run typecheck

# Some errors are warnings in dev mode, check build
npm run build
```

### Build fails
```bash
# Clear build cache
rm -rf dist/

# Rebuild
npm run build
```

### Auth not working
- Check `.env` file is in root directory
- Verify Supabase URL and anon key are correct
- Check Supabase Auth is enabled in project

---

## Performance Tips

1. **Use React.memo** for expensive components
2. **Lazy load routes** with React.lazy
3. **Implement pagination** for large datasets
4. **Cache frequently used data** in state/context
5. **Optimize images** before uploading
6. **Use Tailwind's @apply** to reduce CSS file size

---

## Security Best Practices

1. ✓ Never commit `.env` with real credentials
2. ✓ Use HTTPS in production (Vite handles this)
3. ✓ All database queries filtered by RLS
4. ✓ Auth state validated on every route
5. ✓ No hardcoded secrets in code
6. ✓ CORS will be configured on backend

---

## Next Steps

1. **Test the foundation**
   - Create an account
   - Verify dashboard loads
   - Check navigation works

2. **Build Phase 1 features**
   - Start with task management (highest value)
   - Add real-time updates via Supabase Realtime
   - Implement approval workflows

3. **Add team management**
   - User CRUD operations
   - Department management
   - Role assignments

4. **Complete communication layer**
   - Chat system with WebSockets
   - Real-time notifications
   - Activity logging

---

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [React Documentation](https://react.dev)
- [React Router Documentation](https://reactrouter.com)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

---

## Support

For implementation questions, refer to:
- `IMPLEMENTATION_GUIDE.md` - Detailed architecture and next steps
- `src/types/index.ts` - Data model reference
- Database migration files - Schema reference

---

**Ready to build!** Start with `npm run dev` and open http://localhost:5173
