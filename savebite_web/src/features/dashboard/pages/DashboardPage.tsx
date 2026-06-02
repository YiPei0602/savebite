import { useState, useMemo, useEffect, useRef } from 'react'
import { Users, Store, ShoppingCart, ChevronDown } from 'lucide-react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { format, subDays, subWeeks, subMonths, subYears } from 'date-fns'
import { GenerateReportButton } from '@/shared/components/Common/GenerateReportButton'
import type { OrderRecord, UserRecord } from '@/shared/types/models'
import { subscribeUsers } from '@/features/users/api/usersApi'
import { subscribeOrders } from '@/features/orders/api/ordersApi'

type TimeRange = '1day' | '1week' | '1month' | '3months' | '1year'

function isCompletedOrder(o: OrderRecord): boolean {
  return o.orderStatus?.toLowerCase() === 'completed'
}

export function DashboardPage() {
  const [ordersTimeRange, setOrdersTimeRange] = useState<TimeRange>('1week')
  const [ordersDropdownOpen, setOrdersDropdownOpen] = useState(false)
  const ordersDropdownRef = useRef<HTMLDivElement>(null)
  const [users, setUsers] = useState<UserRecord[]>([])
  const [orders, setOrders] = useState<OrderRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (ordersDropdownRef.current && !ordersDropdownRef.current.contains(event.target as Node)) {
        setOrdersDropdownOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [])

  useEffect(() => {
    setLoading(true)
    setError(null)

    let usersReady = false
    let ordersReady = false
    const maybeFinishLoading = () => {
      if (usersReady && ordersReady) setLoading(false)
    }

    const unsubUsers = subscribeUsers(
      (u) => {
        usersReady = true
        setUsers(u)
        maybeFinishLoading()
      },
      (e) => {
        usersReady = true
        setError(e instanceof Error ? e.message : String(e))
        maybeFinishLoading()
      },
    )

    const unsubOrders = subscribeOrders(
      (ord) => {
        ordersReady = true
        setOrders(ord)
        maybeFinishLoading()
      },
      (e) => {
        ordersReady = true
        setError(e instanceof Error ? e.message : String(e))
        maybeFinishLoading()
      },
    )

    return () => {
      unsubUsers()
      unsubOrders()
    }
  }, [])

  const stats = useMemo(() => {
    const totalConsumers = users.filter((u) => u.role === 'consumer').length
    const totalMerchants = users.filter((u) => u.role === 'merchant').length
    const totalOrders = orders.filter(isCompletedOrder).length

    return {
      totalConsumers,
      totalMerchants,
      totalOrders,
    }
  }, [orders, users])

  function getRangeParams(range: TimeRange) {
    const now = new Date()
    switch (range) {
      case '1day':
        return { startDate: subDays(now, 1), intervalDays: 1 / 24, points: 24, label: 'HH:mm' as const }
      case '1week':
        return { startDate: subWeeks(now, 1), intervalDays: 1, points: 7, label: 'MMM dd' as const }
      case '1month':
        return { startDate: subMonths(now, 1), intervalDays: 1, points: 30, label: 'MMM dd' as const }
      case '3months':
        return { startDate: subMonths(now, 3), intervalDays: 7, points: 12, label: 'MMM dd' as const }
      case '1year':
        return { startDate: subYears(now, 1), intervalDays: 30, points: 12, label: 'MMM' as const }
    }
  }

  function buildTrendData(
    range: TimeRange,
    items: Array<{ ts: string }>,
  ) {
    const { startDate, intervalDays, points, label } = getRangeParams(range)
    const stepMs = intervalDays * 24 * 60 * 60 * 1000
    const buckets = Array.from({ length: points }, (_, i) => new Date(startDate.getTime() + i * stepMs))
    const counts = new Array(points).fill(0) as number[]

    for (const it of items) {
      if (!it.ts) continue
      const dt = new Date(it.ts)
      if (Number.isNaN(dt.getTime())) continue
      const idx = Math.floor((dt.getTime() - startDate.getTime()) / stepMs)
      if (idx >= 0 && idx < points) counts[idx] += 1
    }

    return buckets.map((d, i) => ({
      date: format(d, label),
      orders: counts[i],
    }))
  }

  const ordersTrendData = useMemo(() => {
    const completedWithPaidAt = orders.filter(
      (o) => isCompletedOrder(o) && Boolean(o.paidAt) && !Number.isNaN(new Date(o.paidAt).getTime()),
    )
    return buildTrendData(
      ordersTimeRange,
      completedWithPaidAt.map((o) => ({ ts: o.paidAt })),
    )
  }, [orders, ordersTimeRange])

  const timeRangeOptions = [
    { value: '1day', label: '1 Day' },
    { value: '1week', label: '1 Week' },
    { value: '1month', label: '1 Month' },
    { value: '3months', label: '3 Months' },
    { value: '1year', label: '1 Year' },
  ]

  const getTimeRangeLabel = (value: TimeRange) => {
    return timeRangeOptions.find((opt) => opt.value === value)?.label || '1 Day'
  }

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
      title: 'Total Orders Completed',
      value: stats.totalOrders,
      icon: ShoppingCart,
      color: 'bg-orange-500',
    },
  ]

  const dashboardData = useMemo(
    () => ({
      totalConsumers: stats.totalConsumers,
      totalMerchants: stats.totalMerchants,
      totalOrders: stats.totalOrders,
      ordersTrendData,
      ordersChartRangeLabel:
        timeRangeOptions.find((o) => o.value === ordersTimeRange)?.label ?? '1 Week',
    }),
    [stats, ordersTrendData, ordersTimeRange],
  )

  return (
    <div className="space-y-6">
      {loading && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          Loading dashboard…
        </div>
      )}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600 mt-1">System overview and marketplace analytics</p>
        </div>
        <GenerateReportButton pageContext="dashboard" data={dashboardData} />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
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

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Orders Trend</h2>
          <div className="relative" ref={ordersDropdownRef}>
            <button
              type="button"
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
                    type="button"
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
        <p className="text-xs text-gray-500 mb-2">
          Completed orders from Firestore, grouped by payment time (<code className="text-gray-600">paidAt</code>).
        </p>
        <div
          id="ordersChart"
          className="w-full rounded-lg border border-gray-100 bg-white p-3"
        >
          <p className="text-sm font-semibold text-gray-800 mb-2">
            Orders Trend ({getTimeRangeLabel(ordersTimeRange)})
          </p>
          <div className="h-[300px] w-full min-h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={ordersTrendData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Line type="monotone" dataKey="orders" stroke="#00615F" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  )
}
