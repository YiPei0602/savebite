# 🚀 SaveBite Admin Web - Quick Reference

## 📦 Tech Stack Summary

| Category | Technology | Why? |
|----------|-----------|------|
| **Framework** | React + TypeScript | Industry standard, great ecosystem |
| **Build Tool** | Vite | Fast, modern, excellent DX |
| **UI Library** | Material-UI (MUI) v5 | Professional admin components |
| **State (Server)** | React Query | API data, caching, refetching |
| **State (Client)** | Zustand | Lightweight UI state |
| **Forms** | React Hook Form + Zod | Minimal re-renders, type-safe |
| **Charts** | Recharts | React-native, flexible |
| **Routing** | React Router v6 | Industry standard |
| **HTTP Client** | Axios | Popular, easy to use |

---

## 🗂 Project Structure (Simplified)

```
savebite_web/
├── src/
│   ├── app/              # App config (router, providers)
│   ├── features/         # Feature modules
│   │   ├── auth/        # Login
│   │   ├── users/       # User management
│   │   ├── orders/      # Order monitoring
│   │   ├── donations/   # Donation tracking
│   │   ├── analytics/   # Reports & insights
│   │   └── system/      # System activity
│   ├── shared/          # Reusable components & utils
│   │   ├── components/  # Layout, DataTable, Charts
│   │   ├── hooks/       # Custom hooks
│   │   ├── utils/       # Formatters, validators
│   │   └── api/         # API client
│   └── core/            # Theme, stores, config
```

---

## 🎯 Feature Modules Overview

### 1. **Authentication** (`features/auth/`)
- Login page
- Session management
- Protected routes

### 2. **User Management** (`features/users/`)
- View all users (consumers, merchants, NGOs)
- Filter, search, paginate
- View user details
- Suspend/activate/delete accounts
- Export user data

### 3. **Order Monitoring** (`features/orders/`)
- View all orders
- Filter by status, date, merchant, consumer
- View order details
- Export order data
- Real-time updates

### 4. **Donation Monitoring** (`features/donations/`)
- View all donations
- Filter by NGO, date, status
- Track successful deliveries
- Visualize trends (charts)
- Export donation data

### 5. **Analytics & Reports** (`features/analytics/`)
- Dashboard with KPIs
- Revenue charts
- User growth charts
- Top merchants/consumers
- Category distribution
- Export reports (PDF, CSV)

### 6. **System Activity** (`features/system/`)
- Activity log
- System health monitoring
- Error logs
- Export logs

---

## 🎨 UI Components Hierarchy

```
AppLayout
├── Sidebar (Navigation)
├── Header (Logo, Search, Profile)
└── MainContent
    └── [Feature Pages]
        ├── DataTable (Users, Orders, Donations)
        ├── Charts (Analytics, Donations)
        ├── Forms (User forms, Filters)
        └── Modals (Details, Confirmations)
```

---

## 🔄 Data Flow Example

### Fetching Users

```
Component (UsersListPage)
  ↓
Hook (useUsers)
  ↓
React Query (caching, refetching)
  ↓
Service (userService.getUsers)
  ↓
API Client (axios)
  ↓
Backend API (/admin/users)
  ↓
Firebase Firestore
```

### Updating User

```
Component (UserForm)
  ↓
Hook (useUpdateUser)
  ↓
React Query Mutation
  ↓
Service (userService.updateUser)
  ↓
API Client (axios)
  ↓
Backend API (PATCH /admin/users/:id)
  ↓
Firebase Firestore
  ↓
Invalidate Query (refetch users list)
```

---

## 📋 Key Pages & Routes

| Route | Page | Purpose |
|-------|------|---------|
| `/login` | LoginPage | Admin authentication |
| `/dashboard` | AnalyticsDashboardPage | Main dashboard with KPIs |
| `/users` | UsersListPage | User management table |
| `/users/:id` | UserDetailsPage | Individual user details |
| `/orders` | OrdersListPage | Order monitoring table |
| `/donations` | DonationsPage | Donation tracking |
| `/analytics` | AnalyticsDashboardPage | Reports & insights |
| `/system` | SystemActivityPage | System activity log |

---

## 🛠 Common Patterns

### 1. Data Table Pattern

```typescript
// Component
const UsersListPage = () => {
  const [filters, setFilters] = useState<UserFilters>({});
  const { data, isLoading } = useUsers(filters);
  
  return (
    <DataTable
      data={data}
      columns={userColumns}
      loading={isLoading}
      filters={<UserFilters onChange={setFilters} />}
    />
  );
};
```

### 2. Chart Pattern

```typescript
// Component
const RevenueChart = () => {
  const { data } = useAnalytics({ dateRange: '30d' });
  
  return (
    <ChartContainer title="Revenue Over Time">
      <LineChart data={data.revenue}>
        <Line dataKey="revenue" />
      </LineChart>
    </ChartContainer>
  );
};
```

### 3. Form Pattern

```typescript
// Component
const UserForm = ({ userId }: { userId?: string }) => {
  const { data: user } = useUser(userId);
  const updateUser = useUpdateUser();
  
  const { handleSubmit, control } = useForm<UserFormData>({
    defaultValues: user,
    resolver: zodResolver(userSchema),
  });
  
  const onSubmit = (data: UserFormData) => {
    updateUser.mutate({ userId, data });
  };
  
  return <form onSubmit={handleSubmit(onSubmit)}>...</form>;
};
```

---

## 🔐 Authentication Flow

```
1. Admin enters email/password
2. Frontend calls POST /admin/auth/login
3. Backend validates (Firebase Auth)
4. Backend returns JWT token
5. Frontend stores token (localStorage/httpOnly cookie)
6. Token included in all API requests (Authorization header)
7. Token refresh on expiry
```

---

## 📊 State Management Strategy

### Server State → React Query
- API data (users, orders, donations)
- Automatic caching
- Background refetching
- Optimistic updates

### Client State → Zustand
- UI state (sidebar open/closed)
- Theme (light/dark)
- Filters (temporary)
- Modals (open/closed)

---

## 🎯 Priority Implementation Order

1. ✅ **Project Setup**
   - Initialize React + TypeScript
   - Install dependencies
   - Setup folder structure

2. ✅ **Core Infrastructure**
   - MUI theme
   - React Query setup
   - Zustand stores
   - Routing

3. ✅ **Authentication**
   - Login page
   - Protected routes
   - Auth store

4. ✅ **Layout**
   - AppLayout
   - Sidebar
   - Header

5. ✅ **User Management** (Highest Priority)
   - Users list page
   - User table
   - User details
   - User actions

6. ✅ **Order Monitoring**
   - Orders list page
   - Order table
   - Order details

7. ✅ **Donation Monitoring**
   - Donations page
   - Donation table
   - Charts

8. ✅ **Analytics Dashboard**
   - Dashboard page
   - KPI cards
   - Charts

9. ✅ **System Activity**
   - Activity log
   - System health

---

## 📦 Installation Commands

```bash
# Create project
npm create vite@latest savebite_web -- --template react-ts
cd savebite_web

# Install core dependencies
npm install @mui/material @emotion/react @emotion/styled
npm install @tanstack/react-query
npm install zustand
npm install react-router-dom
npm install axios

# Install form libraries
npm install react-hook-form zod @hookform/resolvers

# Install charts
npm install recharts

# Install utilities
npm install date-fns

# Install dev dependencies
npm install -D @types/node
```

---

## 🚦 Development Commands

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run tests
npm run test

# Lint code
npm run lint
```

---

## 📝 Environment Variables

```env
# .env
VITE_API_BASE_URL=http://localhost:3000/api
VITE_FIREBASE_API_KEY=your-api-key
VITE_FIREBASE_AUTH_DOMAIN=your-auth-domain
VITE_FIREBASE_PROJECT_ID=your-project-id
```

---

## 🎨 Design Tokens

```typescript
// Colors (from mobile app)
primary: '#00695C'    // Teal
accent: '#FF6B00'      // Orange
success: '#4CAF50'     // Green
error: '#F44336'       // Red
warning: '#FF9800'     // Orange

// Typography
fontFamily: 'Inter, Roboto, sans-serif'

// Spacing
paddingXS: 4px
paddingS: 8px
paddingM: 16px
paddingL: 24px
paddingXL: 32px

// Border Radius
radiusS: 4px
radiusM: 8px
radiusL: 16px
```

---

## ✅ Checklist Before Starting

- [ ] Review architecture document
- [ ] Decide on tech stack (confirm React + TypeScript)
- [ ] Setup project structure
- [ ] Install dependencies
- [ ] Configure MUI theme
- [ ] Setup React Query
- [ ] Setup Zustand stores
- [ ] Configure routing
- [ ] Setup API client
- [ ] Create layout components
- [ ] Implement authentication
- [ ] Start with User Management module

---

**Quick Links:**
- Full Architecture: `WEB_FRONTEND_ARCHITECTURE.md`
- Mobile App Structure: `PROJECT_STRUCTURE.md`
- Modules: `MODULES.md`

