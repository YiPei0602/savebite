import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  TextField,
  Button,
  Typography,
  Alert,
  IconButton,
  InputAdornment,
} from '@mui/material'
import VisibilityIcon from '@mui/icons-material/Visibility'
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff'
import { useAuthStore } from '@/core/store/authStore'

const colors = {
  primary: '#00615F', // Deep teal/blue stone
  background: '#F9F3F0', // Warm off-white
  accent: '#FF6B00', // Orange
  white: '#FFFFFF',
}

export function LoginPage() {
  const navigate = useNavigate()
  const { login } = useAuthStore()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await login(email, password)
      navigate('/dashboard')
    } catch (err) {
      setError('Invalid email or password')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Box
      sx={{
        display: 'flex',
        minHeight: '100vh',
        width: '100%',
      }}
    >
      {/* Left Side - Marketing/Image Section */}
      <Box
        sx={{
          flex: 1,
          position: 'relative',
          display: { xs: 'none', md: 'flex' },
          flexDirection: 'column',
          justifyContent: 'space-between',
          backgroundImage: 'url(/assets/images/web_landing.png)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: colors.primary,
            opacity: 0.85, // Dark teal overlay
          },
        }}
      >
        {/* Content with z-index to appear above overlay */}
        <Box
          sx={{
            position: 'relative',
            zIndex: 1,
            p: 6,
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between',
            color: colors.white,
          }}
        >
          {/* Top Logo */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box
              component="img"
              src="/assets/images/logo.png"
              alt="SaveBite"
              sx={{
                height: 48,
                width: 'auto',
              }}
            />
            <Typography
              variant="h4"
              sx={{
                fontWeight: 700,
                color: colors.white,
              }}
            >
              SaveBite
            </Typography>
          </Box>

          {/* Center Content */}
          <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
            <Typography
              variant="h2"
              sx={{
                fontWeight: 700,
                mb: 3,
                color: colors.white,
                fontSize: { md: '3rem', lg: '3.5rem' },
                lineHeight: 1.2,
              }}
            >
              Manage Your Platform
            </Typography>
            <Typography
              variant="h6"
              sx={{
                mb: 4,
                color: colors.white,
                opacity: 0.95,
                fontWeight: 400,
                fontSize: '1.25rem',
              }}
            >
              Monitor users, track orders, analyze performance, and oversee donations — all from one dashboard
            </Typography>

            {/* Feature List */}
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                <Box
                  sx={{
                    color: colors.accent,
                    fontSize: '1.5rem',
                    fontWeight: 'bold',
                  }}
                >
                  ✓
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5 }}>
                    User Management
                  </Typography>
                  <Typography variant="body2" sx={{ opacity: 0.9 }}>
                    Monitor and manage consumers, merchants, and NGOs
                  </Typography>
                </Box>
              </Box>

              <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                <Box
                  sx={{
                    color: colors.accent,
                    fontSize: '1.5rem',
                    fontWeight: 'bold',
                  }}
                >
                  ✓
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5 }}>
                    Analytics & Reports
                  </Typography>
                  <Typography variant="body2" sx={{ opacity: 0.9 }}>
                    Track performance metrics and generate insights
                  </Typography>
                </Box>
              </Box>

              <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                <Box
                  sx={{
                    color: colors.accent,
                    fontSize: '1.5rem',
                    fontWeight: 'bold',
                  }}
                >
                  ✓
                </Box>
                <Box>
                  <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5 }}>
                    System Monitoring
                  </Typography>
                  <Typography variant="body2" sx={{ opacity: 0.9 }}>
                    Monitor orders, donations, and platform activity
                  </Typography>
                </Box>
              </Box>
            </Box>
          </Box>

          {/* Bottom Dots Indicator */}
          <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
            <Box
              sx={{
                width: 8,
                height: 8,
                borderRadius: '50%',
                backgroundColor: colors.white,
                opacity: 1,
              }}
            />
            <Box
              sx={{
                width: 8,
                height: 8,
                borderRadius: '50%',
                backgroundColor: colors.white,
                opacity: 0.4,
              }}
            />
            <Box
              sx={{
                width: 8,
                height: 8,
                borderRadius: '50%',
                backgroundColor: colors.white,
                opacity: 0.4,
              }}
            />
            <Box
              sx={{
                width: 8,
                height: 8,
                borderRadius: '50%',
                backgroundColor: colors.white,
                opacity: 0.4,
              }}
            />
          </Box>
        </Box>
      </Box>

      {/* Right Side - Login Form Section */}
      <Box
        sx={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          backgroundColor: colors.background,
          p: { xs: 4, md: 6 },
          minHeight: '100vh',
        }}
      >
        <Box
          sx={{
            width: '100%',
            maxWidth: 480,
            display: 'flex',
            flexDirection: 'column',
            gap: 4,
          }}
        >
          {/* Logo */}
          <Box sx={{ display: 'flex', justifyContent: 'center', mb: 2 }}>
            <Box
              component="img"
              src="/assets/images/logo.png"
              alt="SaveBite"
              sx={{
                height: 64,
                width: 'auto',
              }}
            />
          </Box>

          {/* Title */}
          <Box sx={{ textAlign: 'center' }}>
            <Typography
              variant="h4"
              sx={{
                fontWeight: 700,
                mb: 1,
                color: '#212121', // Black color
              }}
            >
              Admin Login
            </Typography>
            <Typography
              variant="body1"
              sx={{
                color: '#757575',
              }}
            >
              Sign in to access the admin dashboard
            </Typography>
          </Box>

          {/* Error Alert */}
          {error && (
            <Alert severity="error" sx={{ borderRadius: 2 }}>
              {error}
            </Alert>
          )}

          {/* Login Form */}
          <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <TextField
              fullWidth
              label="Email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoFocus
              sx={{
                '& .MuiOutlinedInput-root': {
                  backgroundColor: colors.white,
                  borderRadius: 2,
                  '&:hover fieldset': {
                    borderColor: colors.primary,
                  },
                  '&.Mui-focused fieldset': {
                    borderColor: colors.primary,
                  },
                },
              }}
            />

            <TextField
              fullWidth
              label="Password"
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={() => setShowPassword(!showPassword)}
                      edge="end"
                      sx={{ color: '#757575' }}
                    >
                      {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
              sx={{
                '& .MuiOutlinedInput-root': {
                  backgroundColor: colors.white,
                  borderRadius: 2,
                  '&:hover fieldset': {
                    borderColor: colors.primary,
                  },
                  '&.Mui-focused fieldset': {
                    borderColor: colors.primary,
                  },
                },
              }}
            />

            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                variant="text"
                sx={{
                  color: colors.primary,
                  textTransform: 'none',
                  fontWeight: 500,
                }}
              >
                Forgot Password?
              </Button>
            </Box>

            <Button
              type="submit"
              fullWidth
              variant="contained"
              disabled={loading}
              sx={{
                backgroundColor: '#212121', // Black color
                color: colors.white,
                py: 1.5,
                borderRadius: 2,
                fontWeight: 600,
                fontSize: '1rem',
                textTransform: 'none',
                '&:hover': {
                  backgroundColor: '#424242',
                },
                '&:disabled': {
                  backgroundColor: '#B0BEC5',
                },
              }}
            >
              {loading ? 'Signing in...' : 'Login'}
            </Button>
          </Box>

          {/* Footer Note */}
          <Box
            sx={{
              mt: 2,
              p: 2,
              backgroundColor: '#E8F5E9', // Light green background
              border: '1px solid #4CAF50', // Green border
              borderRadius: 2,
              textAlign: 'center',
            }}
          >
            <Typography
              variant="caption"
              sx={{
                color: '#2E7D32', // Dark green text
                fontSize: '0.75rem',
                fontWeight: 500,
              }}
            >
              <Box component="span" sx={{ fontWeight: 700 }}>
                Admin Access Only:
              </Box>{' '}
              Only verified administrators can access this dashboard.
            </Typography>
          </Box>
        </Box>
      </Box>
    </Box>
  )
}
