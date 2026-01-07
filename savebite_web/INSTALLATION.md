# SaveBite Admin Dashboard - Installation Guide

## Quick Start

### 1. Install Dependencies
```bash
cd savebite_web
npm install
```

### 2. Start Development Server
```bash
npm run dev
```

The app will start at `http://localhost:3001`

## Tech Stack

- **React 18** - Functional components with hooks
- **TypeScript** - Type safety
- **Tailwind CSS** - Utility-first CSS framework
- **React Router v6** - Client-side routing
- **Zustand** - State management
- **React Query** - Server state management
- **Recharts** - Charts and visualizations
- **jsPDF** - PDF generation
- **Lucide React** - Icon library
- **date-fns** - Date formatting

## Project Structure

```
savebite_web/
├── src/
│   ├── app/                    # App configuration
│   │   ├── App.tsx            # Root component
│   │   └── AppRouter.tsx      # Route configuration
│   ├── features/              # Feature modules
│   │   ├── auth/              # Authentication
│   │   ├── dashboard/         # Dashboard page
│   │   ├── users/             # User management
│   │   ├── donations/         # Donation records
│   │   ├── reports/           # Report generation
│   │   └── profile/           # Admin profile
│   ├── shared/                # Shared components & utilities
│   │   ├── components/        # Reusable components
│   │   ├── data/              # Mock data
│   │   └── utils/             # Utility functions
│   ├── core/                  # Core configuration
│   │   └── store/             # Zustand stores
│   └── styles/                # Global styles
└── public/                    # Static assets
```

## Features Implemented

### ✅ Dashboard
- System overview statistics
- User growth trends
- Donation trends
- Activity summary

### ✅ User Management
- User table with search and filters
- User details view
- Activate/Suspend users
- Delete users (with confirmation)
- Success/error messages

### ✅ Donation Records
- Donation table
- Filter by NGO and date range
- Generate PDF reports
- Export functionality

### ✅ Reports
- Generate Users report
- Generate Donations report
- Generate Orders report
- PDF export

### ✅ Admin Profile
- View profile information
- Edit profile (name, email, phone)
- Change password
- Validation and error handling

## Mock Data

All data is currently mocked in `src/shared/data/mockData.ts`. In production, replace with actual API calls.

## Environment Variables

Create a `.env` file:
```env
VITE_API_BASE_URL=http://localhost:3000/api
```

## Build for Production

```bash
npm run build
```

## Preview Production Build

```bash
npm run preview
```

