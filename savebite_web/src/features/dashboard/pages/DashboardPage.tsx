import { useState, useMemo, useEffect, useRef } from 'react'
import { Users, Store, Building2, ShoppingCart, ChevronDown } from 'lucide-react'
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { mockUsers, mockDonations, mockOrders } from '@/shared/data/mockData'
import { format, subDays, subWeeks, subMonths, subYears } from 'date-fns'
import { GenerateReportButton } from '@/shared/components/Common/GenerateReportButton'

type TimeRange = '1day' | '1week' | '1month' | '3months' | '1year'

const timeRangeOptions = [
  { value: '1day', label: '1 Day' },
  { value: '1week', label: '1 Week' },
  { value: '1month', label: '1 Month' },
  { value: '3months', label: '3 Months' },
  { value: '1year', label: '1 Year' },
]

export function DashboardPage() {
  const [ordersTimeRange, setOrdersTimeRange] = useState<TimeRange>('1week')
  const [donationTimeRange, setDonationTimeRange] = useState<TimeRange>('1week')
  const [ordersDropdownOpen, setOrdersDropdownOpen] = useState(false)
  const [donationDropdownOpen, setDonationDropdownOpen] = useState(false)
  const ordersDropdownRef = useRef<HTMLDivElement>(null)
  const donationDropdownRef = useRef<HTMLDivElement>(null)

  // Close dropdowns when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (ordersDropdownRef.current && !ordersDropdownRef.current.contains(event.target as Node)) {
        setOrdersDropdownOpen(false)
      }
      if (donationDropdownRef.current && !donationDropdownRef.current.contains(event.target as Node)) {
        setDonationDropdownOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [])

  // Calculate statistics
  const stats = useMemo(() => {
    const totalConsumers = mockUsers.filter(u => u.role === 'consumer').length
    const totalMerchants = mockUsers.filter(u => u.role === 'merchant').length
    const totalNGOs = new Set(mockDonations.map(d => d.ngoId)).size
    const totalOrders = mockOrders.filter(o => o.status === 'completed').length

    return {
      totalConsumers,
      totalMerchants,
      totalNGOs,
      totalOrders,
    }
  }, [])

  // Generate Orders Trend Data based on time range
  const ordersTrendData = useMemo(() => {
    const now = new Date()
    let startDate: Date
    let intervalDays: number
    let dataPoints: number

    switch (ordersTimeRange) {
      case '1day':
        startDate = subDays(now, 1)
        intervalDays = 1 / 24 // Hourly
        dataPoints = 24
        break
      case '1week':
        startDate = subWeeks(now, 1)
        intervalDays = 1 // Daily
        dataPoints = 7
        break
      case '1month':
        startDate = subMonths(now, 1)
        intervalDays = 1 // Daily
        dataPoints = 30
        break
      case '3months':
        startDate = subMonths(now, 3)
        intervalDays = 7 // Weekly
        dataPoints = 12
        break
      case '1year':
        startDate = subYears(now, 1)
        intervalDays = 30 // Monthly
        dataPoints = 12
        break
    }

    const data = []
    for (let i = dataPoints - 1; i >= 0; i--) {
      const date = new Date(startDate.getTime() + i * intervalDays * 24 * 60 * 60 * 1000)
      const dateStr = format(date, ordersTimeRange === '1day' ? 'HH:mm' : ordersTimeRange === '1year' ? 'MMM' : 'MMM dd')
      
      // Mock data: simulate orders count
      const baseCount = Math.floor(Math.random() * 10) + 5
      const orders = Math.floor(baseCount + Math.sin(i) * 3)
      
      data.push({
        date: dateStr,
        orders,
      })
    }

    return data
  }, [ordersTimeRange])

  // Generate Donation Trend Data based on time range
  const donationTrendData = useMemo(() => {
    const now = new Date()
    let startDate: Date
    let intervalDays: number
    let dataPoints: number

    switch (donationTimeRange) {
      case '1day':
        startDate = subDays(now, 1)
        intervalDays = 1 / 24 // Hourly
        dataPoints = 24
        break
      case '1week':
        startDate = subWeeks(now, 1)
        intervalDays = 1 // Daily
        dataPoints = 7
        break
      case '1month':
        startDate = subMonths(now, 1)
        intervalDays = 1 // Daily
        dataPoints = 30
        break
      case '3months':
        startDate = subMonths(now, 3)
        intervalDays = 7 // Weekly
        dataPoints = 12
        break
      case '1year':
        startDate = subYears(now, 1)
        intervalDays = 30 // Monthly
        dataPoints = 12
        break
    }

    const data = []
    for (let i = dataPoints - 1; i >= 0; i--) {
      const date = new Date(startDate.getTime() + i * intervalDays * 24 * 60 * 60 * 1000)
      const dateStr = format(date, donationTimeRange === '1day' ? 'HH:mm' : donationTimeRange === '1year' ? 'MMM' : 'MMM dd')
      
      // Mock data: simulate donations count
      const baseCount = Math.floor(Math.random() * 5) + 2
      const donations = Math.floor(baseCount + Math.cos(i) * 2)
      
      data.push({
        date: dateStr,
        donations,
      })
    }

    return data
  }, [donationTimeRange])

  const statCards = [
    {
      title: 'Total Consumers',
      value: stats.totalConsumers,
      icon: Users,
      color: 'bg-blue-500',
    },
    {
      title: 'Total Merchants',
      value: stats.totalMerchants,
      icon: Store,
      color: 'bg-green-500',
    },
    {
      title: 'Total NGOs Served',
      value: stats.totalNGOs,
      icon: Building2,
      color: 'bg-purple-500',
    },
    {
      title: 'Total Orders Completed',
      value: stats.totalOrders,
      icon: ShoppingCart,
      color: 'bg-orange-500',
    },
  ]

  // Dashboard data for report generation
  const dashboardData = useMemo(() => ({
    totalConsumers: stats.totalConsumers,
    totalMerchants: stats.totalMerchants,
    totalNGOs: stats.totalNGOs,
    totalOrders: stats.totalOrders,
  }), [stats])

  const timeRangeOptions = [
    { value: '1day', label: '1 Day' },
    { value: '1week', label: '1 Week' },
    { value: '1month', label: '1 Month' },
    { value: '3months', label: '3 Months' },
    { value: '1year', label: '1 Year' },
  ]

  const getTimeRangeLabel = (value: TimeRange) => {
    return timeRangeOptions.find(opt => opt.value === value)?.label || '1 Day'
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600 mt-1">System overview and analytics</p>
        </div>
        <GenerateReportButton pageContext="dashboard" data={dashboardData} />
      </div>

      {/* Stat Cards - Single Row (4 columns) */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statCards.map((card) => {
          const Icon = card.icon
          return (
            <div
              key={card.title}
              className="bg-white rounded-lg shadow-sm border border-gray-200 p-6"
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{card.title}</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">{card.value}</p>
                </div>
                <div className={`${card.color} p-3 rounded-lg`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {/* Trend Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Orders Trend Chart */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Orders Trend</h2>
            <div className="relative" ref={ordersDropdownRef}>
              <button
                onClick={() => setOrdersDropdownOpen(!ordersDropdownOpen)}
                className="flex items-center gap-2 px-3 py-1.5 text-sm border border-gray-300 rounded-lg bg-white hover:bg-gray-50 transition-colors"
              >
                <span>{getTimeRangeLabel(ordersTimeRange)}</span>
                <ChevronDown className="w-4 h-4" />
              </button>
              {ordersDropdownOpen && (
                <div className="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-lg shadow-lg z-10">
                  {timeRangeOptions.map((option) => (
                    <button
                      key={option.value}
                      onClick={() => {
                        setOrdersTimeRange(option.value as TimeRange)
                        setOrdersDropdownOpen(false)
                      }}
                      className={`w-full text-left px-4 py-2 text-sm hover:bg-gray-50 transition-colors ${
                        ordersTimeRange === option.value
                          ? 'bg-primary text-white hover:bg-primary-dark'
                          : 'text-gray-700'
                      } ${option.value === timeRangeOptions[0].value ? 'rounded-t-lg' : ''} ${
                        option.value === timeRangeOptions[timeRangeOptions.length - 1].value ? 'rounded-b-lg' : ''
                      }`}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={ordersTrendData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Line type="monotone" dataKey="orders" stroke="#00615F" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Donation Trend Chart */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Donation Trend</h2>
            <div className="relative" ref={donationDropdownRef}>
              <button
                onClick={() => setDonationDropdownOpen(!donationDropdownOpen)}
                className="flex items-center gap-2 px-3 py-1.5 text-sm border border-gray-300 rounded-lg bg-white hover:bg-gray-50 transition-colors"
              >
                <span>{getTimeRangeLabel(donationTimeRange)}</span>
                <ChevronDown className="w-4 h-4" />
              </button>
              {donationDropdownOpen && (
                <div className="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-lg shadow-lg z-10">
                  {timeRangeOptions.map((option) => (
                    <button
                      key={option.value}
                      onClick={() => {
                        setDonationTimeRange(option.value as TimeRange)
                        setDonationDropdownOpen(false)
                      }}
                      className={`w-full text-left px-4 py-2 text-sm hover:bg-gray-50 transition-colors ${
                        donationTimeRange === option.value
                          ? 'bg-primary text-white hover:bg-primary-dark'
                          : 'text-gray-700'
                      } ${option.value === timeRangeOptions[0].value ? 'rounded-t-lg' : ''} ${
                        option.value === timeRangeOptions[timeRangeOptions.length - 1].value ? 'rounded-b-lg' : ''
                      }`}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={donationTrendData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="donations" fill="#FF6B00" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}
