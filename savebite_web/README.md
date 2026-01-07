# SaveBite Admin Dashboard

Production-ready admin dashboard for managing the SaveBite platform.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## 📋 Features

- **Dashboard** - System overview with statistics and charts
- **User Management** - Search, filter, activate, suspend, and delete users
- **Donation Records** - View donations and generate PDF reports
- **Reports** - Generate and export system reports
- **Profile** - Manage admin profile and password

## 🛠 Tech Stack

- React 18 + TypeScript
- Tailwind CSS
- React Router v6
- Zustand (State Management)
- React Query (Server State)
- Recharts (Charts)
- jsPDF (PDF Export)
- Lucide React (Icons)

## 📁 Project Structure

```
src/
├── app/              # App configuration
├── features/         # Feature modules
│   ├── auth/         # Authentication
│   ├── dashboard/    # Dashboard
│   ├── users/        # User management
│   ├── donations/    # Donation records
│   ├── reports/      # Reports
│   └── profile/      # Admin profile
├── shared/           # Shared components & utilities
└── core/             # Core configuration
```

## 📝 Documentation

- [Installation Guide](./INSTALLATION.md)
- [Architecture Document](../WEB_FRONTEND_ARCHITECTURE.md)

## 🔐 Login

Default credentials (mock):
- Email: Any email
- Password: Any password

In production, replace with actual authentication.
