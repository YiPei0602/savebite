import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  Users,
  HeartHandshake,
  User,
} from 'lucide-react'

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/dashboard' },
  { icon: Users, label: 'Users', path: '/users' },
  { icon: HeartHandshake, label: 'Donations', path: '/donations' },
  { icon: User, label: 'Profile', path: '/profile' },
]

export function Sidebar() {
  return (
    <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
      {/* Logo */}
      <div className="h-16 flex items-center px-6 border-b border-gray-200">
        <img
          src="/assets/images/logo_round.png"
          alt="SaveBite"
          className="h-14 w-14 object-contain mr-3"
        />
        <span className="text-xl font-bold text-gray-900">SaveBite</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-4 py-6 space-y-1">
        {menuItems.map((item) => {
          const Icon = item.icon
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors duration-200 ${
                  isActive
                    ? 'bg-orange-500 text-white'
                    : 'text-gray-700 hover:bg-orange-500 hover:text-white'
                }`
              }
            >
              <Icon className="w-5 h-5 mr-3" />
              {item.label}
            </NavLink>
          )
        })}
      </nav>
    </aside>
  )
}
