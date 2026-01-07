import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Lock, Check, Eye, EyeOff, CheckCircle2 } from 'lucide-react'
import { useAuthStore } from '@/core/store/authStore'

const colors = {
  primary: '#00615F',
  background: '#F9F3F0',
  accent: '#FF6B00',
  white: '#FFFFFF',
}

export function LoginPage() {
  const navigate = useNavigate()
  const { login } = useAuthStore()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [emailError, setEmailError] = useState('')
  const [loading, setLoading] = useState(false)
  const [isEmailValid, setIsEmailValid] = useState(false)

  // Email validation
  const validateEmail = (email: string) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }

  useEffect(() => {
    if (email.length > 0) {
      if (validateEmail(email)) {
        setIsEmailValid(true)
        setEmailError('')
      } else {
        setIsEmailValid(false)
        setEmailError('Please enter a valid email address')
      }
    } else {
      setIsEmailValid(false)
      setEmailError('')
    }
  }, [email])

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
    <div className="flex min-h-screen w-full">
      {/* Left Side - Admin Context Section (1/2 width) */}
      <div
        className="w-1/2 relative hidden md:flex flex-col justify-between bg-cover bg-center"
        style={{
          backgroundImage: 'url(/assets/images/web_landing.png)',
        }}
      >
        {/* Overlay with increased opacity (75%) */}
        <div
          className="absolute inset-0"
          style={{ backgroundColor: colors.primary, opacity: 0.75 }}
        />
        
        <div className="relative z-10 p-6 h-full flex flex-col text-white">
          {/* Top Logo & Branding */}
          <div className="mb-8">
            <div className="flex items-center gap-4">
              <img
                src="/assets/images/logo_round.png"
                alt="SaveBite"
                className="h-28 w-28 object-contain flex-shrink-0"
              />
              <div className="flex flex-col">
                <h1 className="text-2xl font-bold leading-tight">SaveBite</h1>
                <p className="text-base font-medium text-white leading-relaxed">
                  Surplus Food Management & Redistribution
                </p>
              </div>
            </div>
          </div>

          {/* Center Content */}
          <div className="flex-1 flex flex-col justify-center">
            <h2 className="text-3xl md:text-4xl font-bold mb-4 leading-tight">
              SaveBite Administration Portal
            </h2>
            <p className="text-base md:text-lg mb-12 opacity-95 leading-relaxed">
              Secure access for system administrators to manage users,<br />
              monitor platform activity, and oversee donation operations.
            </p>
          </div>

          {/* Feature List - Subtle Secondary Style */}
          <div className="flex flex-col gap-4 mt-auto pb-12">
            {/* User & Role Management */}
            <div className="flex items-center gap-3 opacity-75 transition-opacity hover:opacity-90">
              <div className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: colors.accent }}>
                <Check className="w-3.5 h-3.5 text-white" />
              </div>
              <p className="text-sm font-medium text-white">Manage 500+ Users & Permissions</p>
            </div>

            {/* System Monitoring */}
            <div className="flex items-center gap-3 opacity-75 transition-opacity hover:opacity-90">
              <div className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: colors.accent }}>
                <Check className="w-3.5 h-3.5 text-white" />
              </div>
              <p className="text-sm font-medium text-white">Real-time System Analytics</p>
            </div>

            {/* Donation Oversight */}
            <div className="flex items-center gap-3 opacity-75 transition-opacity hover:opacity-90">
              <div className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: colors.accent }}>
                <Check className="w-3.5 h-3.5 text-white" />
              </div>
              <p className="text-sm font-medium text-white">Track NGO Donations & Impact</p>
            </div>
          </div>
        </div>
      </div>

      {/* Right Side - Login Form Section (1/2 width) */}
      <div
        className="w-1/2 flex flex-col justify-center items-center p-6 md:p-12 min-h-screen"
        style={{ backgroundColor: colors.background }}
      >
        {/* Login Card with Shadow and Border */}
        <div className="w-full max-w-md bg-white rounded-lg shadow-lg border border-gray-200 p-8 flex flex-col gap-6">
          {/* Logo - Using logo_round.png (already round, no shape manipulation) */}
          <div className="flex justify-center mb-2 animate-fade-in">
            <img
              src="/assets/images/logo_round.png"
              alt="SaveBite"
              className="h-40 w-40 object-contain"
            />
          </div>

          {/* Title */}
          <div className="text-center">
            <h1 className="text-3xl font-bold mb-2" style={{ color: '#212121' }}>
              Admin Login
            </h1>
            <p className="text-gray-600 text-sm">Sign in to access the admin dashboard</p>
          </div>

          {/* Error Alert */}
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="flex flex-col gap-5">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Email *
              </label>
              <div className="relative">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  autoFocus
                  aria-label="Email address"
                  className={`w-full px-4 py-2.5 bg-white border rounded-lg focus:ring-4 focus:border-transparent transition-all pr-10 ${
                    email.length > 0
                      ? isEmailValid
                        ? 'border-green-500 focus:ring-green-100'
                        : 'border-red-400 focus:ring-red-100'
                      : 'border-gray-300 focus:ring-blue-100'
                  }`}
                  placeholder="admin@savebite.com"
                />
                {email.length > 0 && isEmailValid && (
                  <CheckCircle2 className="w-5 h-5 text-green-500 absolute right-3 top-1/2 transform -translate-y-1/2" />
                )}
              </div>
              {email.length > 0 && emailError && (
                <p className="text-xs text-red-600 mt-1">{emailError}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Password *
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  aria-label="Password"
                  className="w-full px-4 py-2.5 bg-white border border-gray-300 rounded-lg focus:ring-4 focus:ring-blue-100 focus:border-transparent pr-10 transition-all"
                  placeholder="Enter your password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  title={showPassword ? 'Hide password' : 'Show password'}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700 transition-colors"
                >
                  {showPassword ? (
                    <EyeOff className="w-5 h-5" />
                  ) : (
                    <Eye className="w-5 h-5" />
                  )}
                </button>
              </div>
              
              {/* Forgot Password */}
              <div className="mt-2 flex justify-end">
                <button
                  type="button"
                  className="text-xs text-gray-500 hover:text-gray-700 hover:underline transition-colors"
                >
                  Forgot Password?
                </button>
              </div>
            </div>

            {/* CTA Button with Loading Spinner */}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 px-4 bg-black text-white rounded-lg font-semibold hover:bg-gray-800 hover:scale-105 active:scale-100 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100 transition-all duration-200 flex items-center justify-center gap-2 shadow-md hover:shadow-lg"
            >
              {loading ? (
                <>
                  <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>Signing in...</span>
                </>
              ) : (
                'Sign in as Administrator'
              )}
            </button>
          </form>

          {/* Security Message - Subtle Notice with Lock Icon */}
          <div className="mt-4 pt-4 border-t border-gray-200">
            <div className="flex items-center gap-2 text-xs text-gray-600 bg-gray-50 border border-gray-200 rounded-lg px-3 py-2">
              <Lock className="w-3.5 h-3.5 text-gray-500" />
              <span>Restricted access — verified administrators only</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
