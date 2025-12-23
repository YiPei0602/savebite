# SaveBite Admin Web Dashboard

Admin web interface for managing the SaveBite platform.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and npm

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 📁 Project Structure

```
savebite_web/
├── src/
│   ├── app/              # App configuration (router, providers)
│   ├── features/         # Feature modules
│   │   ├── auth/         # Authentication
│   │   ├── users/        # User management
│   │   ├── orders/       # Order monitoring
│   │   ├── donations/    # Donation tracking
│   │   ├── analytics/    # Analytics & reports
│   │   └── system/       # System activity
│   ├── shared/           # Shared components & utilities
│   ├── core/             # Core configuration (theme, stores)
│   └── main.tsx          # Entry point
├── public/               # Static assets
└── package.json
```

## 🛠 Tech Stack

- **React 18** + **TypeScript**
- **Vite** - Build tool
- **Material-UI (MUI)** - UI component library
- **React Query** - Server state management
- **Zustand** - Client state management
- **React Router** - Routing
- **Axios** - HTTP client
- **Recharts** - Charts & visualizations

## 📚 Documentation

- [Architecture Document](../WEB_FRONTEND_ARCHITECTURE.md)
- [Quick Reference](../WEB_FRONTEND_QUICK_REFERENCE.md)
- [Decision Matrix](../WEB_FRONTEND_DECISIONS.md)

## 🔐 Environment Variables

Copy `.env.example` to `.env` and fill in your configuration:

```bash
cp .env.example .env
```

## 📝 Development

See the architecture documents for detailed information about:
- Feature modules
- Component architecture
- State management
- API integration
- Routing strategy

