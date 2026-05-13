import { useState, useEffect } from 'react'
import { FileText, Download, X } from 'lucide-react'
import jsPDF from 'jspdf'
import html2canvas from 'html2canvas'
import { format, subDays, subWeeks, subMonths, subYears } from 'date-fns'

type TrendRow = { date: string; orders: number }

async function waitForChartPaint(): Promise<void> {
  await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()))
  await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()))
  await new Promise((r) => setTimeout(r, 150))
}

async function captureOrdersChartPng(): Promise<{ dataUrl: string; aspect: number } | null> {
  const el = document.getElementById('ordersChart')
  if (!el) return null
  const { width, height } = el.getBoundingClientRect()
  if (width < 8 || height < 8) return null
  try {
    const canvas = await html2canvas(el, {
      scale: 2,
      useCORS: true,
      backgroundColor: '#ffffff',
      logging: false,
    })
    return {
      dataUrl: canvas.toDataURL('image/png'),
      aspect: canvas.height / Math.max(canvas.width, 1),
    }
  } catch (e) {
    console.warn('ordersChart capture failed', e)
    return null
  }
}

function buildDashboardInsightBullets(rows: TrendRow[] | undefined): string[] {
  const list = Array.isArray(rows)
    ? rows.map((r) => ({ date: String(r.date), orders: Number(r.orders) || 0 }))
    : []
  if (list.length === 0) {
    return ['No completed orders in the current chart window for this time range.']
  }
  const first = list[0]!.orders
  const last = list[list.length - 1]!.orders
  let trend: string
  if (last > first) {
    trend = 'Completed orders trend upward toward the end of the selected period.'
  } else if (last < first) {
    trend = 'Higher completed-order volume appears earlier in the selected period.'
  } else {
    trend = 'Completed-order volume is relatively steady across the selected period.'
  }
  let maxI = 0
  for (let i = 1; i < list.length; i++) {
    if (list[i]!.orders > list[maxI]!.orders) maxI = i
  }
  const peak = `Peak in chart: ${list[maxI]!.date} (${list[maxI]!.orders} completed).`
  return [trend, peak]
}

interface GenerateReportButtonProps {
  pageContext: 'dashboard' | 'users' | 'profile'
  data?: any
  onGeneratingChange?: (loading: boolean) => void
}

export function GenerateReportButton({
  pageContext,
  data,
  onGeneratingChange,
}: GenerateReportButtonProps) {
  const [showModal, setShowModal] = useState(false)
  const [dateRange, setDateRange] = useState('1week')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [isGenerating, setIsGenerating] = useState(false)
  const [showSuccess, setShowSuccess] = useState(false)

  // Dashboard-specific state
  const [dashboardMetrics, setDashboardMetrics] = useState({
    totalConsumers: true,
    totalMerchants: true,
    totalOrders: true,
    ordersTrend: true,
  })

  // Users-specific state
  const [userTypeFilter, setUserTypeFilter] = useState('all')
  const [userStatusFilter, setUserStatusFilter] = useState('all')

  // Initialize date range on mount
  useEffect(() => {
    handleDateRangeChange('1week')
  }, [])

  useEffect(() => {
    onGeneratingChange?.(isGenerating)
  }, [isGenerating, onGeneratingChange])

  const handleDateRangeChange = (range: string) => {
    setDateRange(range)
    const now = new Date()
    let start = new Date()
    
    switch (range) {
      case '1day':
        start = subDays(now, 1)
        break
      case '1week':
        start = subWeeks(now, 1)
        break
      case '1month':
        start = subMonths(now, 1)
        break
      case '3months':
        start = subMonths(now, 3)
        break
      case '1year':
        start = subYears(now, 1)
        break
    }
    
    setStartDate(format(start, 'yyyy-MM-dd'))
    setEndDate(format(now, 'yyyy-MM-dd'))
  }

  const handleGenerateReport = async () => {
    setIsGenerating(true)
    try {
      const doc = new jsPDF()

      const titles = {
        dashboard: 'SaveBite System Report',
        users: 'SaveBite User Management Report',
        profile: 'SaveBite Report',
      }

      if (pageContext === 'dashboard') {
        // Close modal so #ordersChart is visible for html2canvas (overlay would block capture).
        setShowModal(false)
        await waitForChartPaint()
        await new Promise((r) => setTimeout(r, 200))
        await appendDashboardReportToPdf(doc)
      } else {
        doc.setFontSize(18)
        doc.setFont('helvetica', 'bold')
        doc.text(titles[pageContext] || 'SaveBite Report', 14, 20)

        doc.setFontSize(12)
        doc.setFont('helvetica', 'normal')
        let yPos = 30
        doc.text(`Report Generated: ${format(new Date(), 'MMM dd, yyyy HH:mm')}`, 14, yPos)
        yPos += 10

        if (startDate && endDate) {
          doc.text(
            `Date Range: ${format(new Date(startDate), 'MMM dd, yyyy')} - ${format(new Date(endDate), 'MMM dd, yyyy')}`,
            14,
            yPos,
          )
          yPos += 10
        } else {
          doc.text(`Time Range: ${dateRange}`, 14, yPos)
          yPos += 10
        }

        yPos += 5

        if (pageContext === 'users') {
          generateUsersReport(doc, yPos, Array.isArray(data) ? data : [])
        }
      }

      const fileName = `${pageContext}-report-${format(new Date(), 'yyyy-MM-dd')}.pdf`
      doc.save(fileName)

      setShowModal(false)
      setShowSuccess(true)
      setTimeout(() => setShowSuccess(false), 3000)
    } catch (e) {
      console.error(e)
      alert('Could not generate PDF. Please try again.')
    } finally {
      setIsGenerating(false)
    }
  }

  const appendDashboardReportToPdf = async (doc: jsPDF) => {
    const pageW = doc.internal.pageSize.getWidth()
    const margin = 14
    const contentW = pageW - margin * 2
    const primaryRgb: [number, number, number] = [0, 97, 95]

    doc.setFont('helvetica', 'bold')
    doc.setFontSize(18)
    doc.setTextColor(20, 20, 20)
    doc.text('SaveBite System Report', pageW / 2, 24, { align: 'center' })

    doc.setFontSize(11)
    doc.setFont('helvetica', 'normal')
    doc.setTextColor(85, 85, 85)
    doc.text('System Analytics Report', pageW / 2, 32, { align: 'center' })

    let y = 42
    doc.setDrawColor(210)
    doc.setLineWidth(0.3)
    doc.line(margin, y, pageW - margin, y)
    y += 10

    doc.setFontSize(10)
    doc.setTextColor(55, 55, 55)
    doc.setFont('helvetica', 'normal')
    doc.text(`Report generated: ${format(new Date(), 'MMM dd, yyyy HH:mm')}`, margin, y)
    y += 6
    if (startDate && endDate) {
      doc.text(
        `Date range: ${format(new Date(startDate), 'MMM dd, yyyy')} – ${format(new Date(endDate), 'MMM dd, yyyy')}`,
        margin,
        y,
      )
    } else {
      doc.text(`Report period preset: ${dateRange}`, margin, y)
    }
    y += 14

    doc.setFont('helvetica', 'bold')
    doc.setFontSize(13)
    doc.setTextColor(...primaryRgb)
    doc.text('Summary', margin, y)
    y += 10

    const summaryItems: { label: string; value: number; show: boolean }[] = [
      { label: 'Total Consumers', value: Number(data?.totalConsumers) || 0, show: dashboardMetrics.totalConsumers },
      { label: 'Total Merchants', value: Number(data?.totalMerchants) || 0, show: dashboardMetrics.totalMerchants },
      {
        label: 'Total Orders Completed',
        value: Number(data?.totalOrders) || 0,
        show: dashboardMetrics.totalOrders,
      },
    ]

    for (const row of summaryItems) {
      if (!row.show) continue
      doc.setFont('helvetica', 'normal')
      doc.setFontSize(9)
      doc.setTextColor(110, 110, 110)
      doc.text(row.label, margin, y)
      y += 6
      doc.setFont('helvetica', 'bold')
      doc.setFontSize(20)
      doc.setTextColor(...primaryRgb)
      doc.text(String(row.value), margin, y + 2)
      y += 16
    }

    y += 6
    doc.setDrawColor(220)
    doc.line(margin, y, pageW - margin, y)
    y += 12

    if (dashboardMetrics.ordersTrend) {
      doc.setFont('helvetica', 'bold')
      doc.setFontSize(13)
      doc.setTextColor(...primaryRgb)
      doc.text('Orders Trend', margin, y)
      y += 7
      doc.setFont('helvetica', 'normal')
      doc.setFontSize(9)
      doc.setTextColor(95, 95, 95)
      const rangeLabel = data?.ordersChartRangeLabel ?? 'Dashboard selection'
      doc.text(`Completed orders (paidAt), chart range: ${rangeLabel}`, margin, y)
      y += 10

      await waitForChartPaint()
      const cap = await captureOrdersChartPng()
      if (cap) {
        const imgW = contentW
        const imgH = imgW * cap.aspect
        if (y + imgH > 275) {
          doc.addPage()
          y = margin
        }
        try {
          doc.addImage(cap.dataUrl, 'PNG', margin, y, imgW, imgH)
          y += imgH + 12
        } catch {
          doc.setFontSize(10)
          doc.setTextColor(130, 130, 130)
          doc.text('Could not embed chart image.', margin, y)
          y += 10
        }
      } else {
        doc.setFontSize(10)
        doc.setTextColor(130, 130, 130)
        const fallback = doc.splitTextToSize(
          'Chart not captured (ensure the Orders Trend chart is visible; element #ordersChart missing).',
          contentW,
        )
        for (const line of fallback) {
          doc.text(line, margin, y)
          y += 5
        }
        y += 8
      }
    }

    y += 4
    if (y > 240) {
      doc.addPage()
      y = margin
    }
    doc.setDrawColor(220)
    doc.line(margin, y, pageW - margin, y)
    y += 12

    doc.setFont('helvetica', 'bold')
    doc.setFontSize(13)
    doc.setTextColor(...primaryRgb)
    doc.text('Insights', margin, y)
    y += 9
    doc.setFont('helvetica', 'normal')
    doc.setFontSize(10)
    doc.setTextColor(45, 45, 45)
    const bullets = buildDashboardInsightBullets(data?.ordersTrendData as TrendRow[] | undefined)
    for (const b of bullets) {
      const wrapped = doc.splitTextToSize(`• ${b}`, contentW)
      for (const line of wrapped) {
        if (y > 278) {
          doc.addPage()
          y = margin
        }
        doc.text(line, margin, y)
        y += 5
      }
      y += 2
    }
  }

  const generateUsersReport = (doc: jsPDF, startY: number, usersInput: any[]) => {
    let yPos = startY
    doc.setFontSize(10)
    doc.setFont('helvetica', 'bold')
    doc.text('User Account Report', 14, yPos)
    yPos += 10

    // Apply filters
    let filteredUsers = usersInput

    if (userTypeFilter !== 'all') {
      filteredUsers = filteredUsers.filter(u => u.role === userTypeFilter)
    }

    if (userStatusFilter !== 'all') {
      filteredUsers = filteredUsers.filter(u => u.status === userStatusFilter)
    }

    // Filter by date range (createdAt)
    if (startDate && endDate) {
      const start = new Date(startDate)
      const end = new Date(endDate)
      filteredUsers = filteredUsers.filter(u => {
        const createdAt = new Date(u.createdAt)
        return createdAt >= start && createdAt <= end
      })
    }

    doc.setFont('helvetica', 'normal')
    doc.text(`Total Users: ${filteredUsers.length}`, 14, yPos)
    yPos += 10

    if (userTypeFilter !== 'all') {
      doc.text(`User Type: ${userTypeFilter.charAt(0).toUpperCase() + userTypeFilter.slice(1)}`, 14, yPos)
      yPos += 7
    }

    if (userStatusFilter !== 'all') {
      doc.text(`Status: ${userStatusFilter.charAt(0).toUpperCase() + userStatusFilter.slice(1)}`, 14, yPos)
      yPos += 7
    }

    yPos += 5
    doc.setFont('helvetica', 'bold')
    doc.text('User Details', 14, yPos)
    yPos += 7
    doc.setFont('helvetica', 'normal')

    filteredUsers.slice(0, 50).forEach((user: any) => {
      if (yPos > 280) {
        doc.addPage()
        yPos = 20
      }
      doc.text(`${user.name} (${user.email})`, 14, yPos)
      yPos += 5
      doc.text(`  Role: ${user.role} | Status: ${user.status} | Created: ${format(new Date(user.createdAt), 'MMM dd, yyyy')}`, 14, yPos)
      yPos += 7
    })
  }

  // Don't render button for profile page
  if (pageContext === 'profile') {
    return null
  }

  const modalTitles: Record<'dashboard' | 'users', string> = {
    dashboard: 'Generate System Report',
    users: 'Generate User Report',
  }

  return (
    <>
      {/* Success Message */}
      {showSuccess && (
        <div className="fixed top-4 right-4 bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg shadow-lg z-50">
          Report exported successfully
        </div>
      )}

      {/* Generate Report Button */}
      <button
        type="button"
        disabled={isGenerating}
        onClick={() => setShowModal(true)}
        className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <FileText className="w-4 h-4" />
        Generate Report
      </button>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900">{modalTitles[pageContext]}</h3>
              <button
                type="button"
                disabled={isGenerating}
                onClick={() => setShowModal(false)}
                className="text-gray-400 hover:text-gray-600 disabled:opacity-40"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4">
              {/* Date Range - Common for all pages */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Date Range *
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {[
                    { value: '1day', label: '1 Day' },
                    { value: '1week', label: '1 Week' },
                    { value: '1month', label: '1 Month' },
                    { value: '3months', label: '3 Months' },
                    { value: '1year', label: '1 Year' },
                  ].map((option) => (
                    <button
                      key={option.value}
                      onClick={() => handleDateRangeChange(option.value)}
                      className={`px-4 py-2 text-sm rounded-lg border transition-colors ${
                        dateRange === option.value
                          ? 'bg-primary text-white border-primary'
                          : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                      }`}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Custom Date Range */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Custom Date Range (Optional)
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
                  />
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
                  />
                </div>
              </div>

              {/* Dashboard-specific: Report Content Selection */}
              {pageContext === 'dashboard' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Report Content (Select metrics to include)
                  </label>
                  <div className="space-y-2 border border-gray-200 rounded-lg p-3">
                    {[
                      { key: 'totalConsumers', label: 'Total Consumers' },
                      { key: 'totalMerchants', label: 'Total Merchants' },
                      { key: 'totalOrders', label: 'Total Orders Completed' },
                      { key: 'ordersTrend', label: 'Orders Trend' },
                    ].map((metric) => (
                      <label key={metric.key} className="flex items-center gap-2 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={dashboardMetrics[metric.key as keyof typeof dashboardMetrics]}
                          onChange={(e) =>
                            setDashboardMetrics({
                              ...dashboardMetrics,
                              [metric.key]: e.target.checked,
                            })
                          }
                          className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
                        />
                        <span className="text-sm text-gray-700">{metric.label}</span>
                      </label>
                    ))}
                  </div>
                </div>
              )}

              {/* Users-specific: Filters */}
              {pageContext === 'users' && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      User Type Filter
                    </label>
                    <select
                      value={userTypeFilter}
                      onChange={(e) => setUserTypeFilter(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
                    >
                      <option value="all">All Users</option>
                      <option value="consumer">Consumers</option>
                      <option value="merchant">Merchants</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Account Status Filter
                    </label>
                    <select
                      value={userStatusFilter}
                      onChange={(e) => setUserStatusFilter(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
                    >
                      <option value="all">All Statuses</option>
                      <option value="active">Active</option>
                      <option value="suspended">Suspended</option>
                      <option value="inactive">Inactive</option>
                    </select>
                  </div>
                </>
              )}

            </div>

            <div className="flex gap-3 justify-end mt-6">
              <button
                type="button"
                disabled={isGenerating}
                onClick={() => setShowModal(false)}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleGenerateReport}
                disabled={isGenerating}
                className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary rounded-lg hover:bg-primary-dark disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isGenerating ? (
                  <>
                    <svg className="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Generating...
                  </>
                ) : (
                  <>
                    <Download className="w-4 h-4" />
                    Export PDF
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
