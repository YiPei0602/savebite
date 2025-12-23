import { useNavigate, useLocation } from 'react-router-dom'
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Box,
} from '@mui/material'
import DashboardIcon from '@mui/icons-material/Dashboard'
import PeopleIcon from '@mui/icons-material/People'
import ReceiptIcon from '@mui/icons-material/Receipt'
import VolunteerActivismIcon from '@mui/icons-material/VolunteerActivism'
import AnalyticsIcon from '@mui/icons-material/Analytics'
import MonitorHeartIcon from '@mui/icons-material/MonitorHeart'
import { useUIStore } from '@/core/store/uiStore'

const drawerWidth = 260

const menuItems = [
  { text: 'Dashboard', icon: DashboardIcon, path: '/dashboard' },
  { text: 'Users', icon: PeopleIcon, path: '/users' },
  { text: 'Orders', icon: ReceiptIcon, path: '/orders' },
  { text: 'Donations', icon: VolunteerActivismIcon, path: '/donations' },
  { text: 'Analytics', icon: AnalyticsIcon, path: '/analytics' },
  { text: 'System Activity', icon: MonitorHeartIcon, path: '/system' },
]

export function Sidebar() {
  const navigate = useNavigate()
  const location = useLocation()
  const { sidebarOpen, setSidebarOpen } = useUIStore()

  return (
    <Drawer
      variant="persistent"
      open={sidebarOpen}
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: drawerWidth,
          boxSizing: 'border-box',
        },
      }}
    >
      <Toolbar>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Box
            component="img"
            src="/assets/logos/logo.png"
            alt="SaveBite"
            sx={{ height: 32, width: 'auto' }}
          />
          <Box sx={{ fontWeight: 600, fontSize: '1.25rem' }}>SaveBite</Box>
        </Box>
      </Toolbar>
      <List>
        {menuItems.map((item) => {
          const Icon = item.icon
          const isActive = location.pathname === item.path
          return (
            <ListItem key={item.text} disablePadding>
              <ListItemButton
                selected={isActive}
                onClick={() => navigate(item.path)}
                sx={{
                  '&.Mui-selected': {
                    backgroundColor: 'primary.main',
                    color: 'primary.contrastText',
                    '&:hover': {
                      backgroundColor: 'primary.dark',
                    },
                    '& .MuiListItemIcon-root': {
                      color: 'primary.contrastText',
                    },
                  },
                }}
              >
                <ListItemIcon>
                  <Icon />
                </ListItemIcon>
                <ListItemText primary={item.text} />
              </ListItemButton>
            </ListItem>
          )
        })}
      </List>
    </Drawer>
  )
}

