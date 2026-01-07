import { useState, useEffect } from 'react'
import { FileText, Download, X } from 'lucide-react'
import jsPDF from 'jspdf'
import { format, subDays, subWeeks, subMonths, subYears } from 'date-fns'
import { mockUsers, mockDonations, User, Donation } from '@/shared/data/mockData'

interface GenerateReportButtonProps {
  pageContext: 'dashboard' | 'users' | 'donations' | 'profile'
  data?: any
}

export function GenerateReportButton({ pageContext, data }: GenerateReportButtonProps) {
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
    totalNGOs: true,
    totalOrders: true,
    ordersTrend: true,
    donationTrend: true,
  })

  // Users-specific state
  const [userTypeFilter, setUserTypeFilter] = useState('all')
  const [userStatusFilter, setUserStatusFilter] = useState('all')

  // Donations-specific state
  const [donationMerchantFilter, setDonationMerchantFilter] = useState('all')
  const [donationNGOFilter, setDonationNGOFilter] = useState('all')

  // Initialize date range on mount
  useEffect(() => {
    handleDateRangeChange('1week')
  }, [])

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

    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 1500))

    const doc = new jsPDF()
    
    // Title based on context
    const titles = {
      dashboard: 'SaveBite System Report',
      users: 'SaveBite User Management Report',
      donations: 'SaveBite Donation Report',
    }
    
    doc.setFontSize(18)
    doc.text(titles[pageContext] || 'SaveBite Report', 14, 20)
    
    // Criteria
    doc.setFontSize(12)
    let yPos = 30
    doc.text(`Report Generated: ${format(new Date(), 'MMM dd, yyyy HH:mm')}`, 14, yPos)
    yPos += 10
    
    if (startDate && endDate) {
      doc.text(`Date Range: ${format(new Date(startDate), 'MMM dd, yyyy')} - ${format(new Date(endDate), 'MMM dd, yyyy')}`, 14, yPos)
      yPos += 10
    } else {
      doc.text(`Time Range: ${dateRange}`, 14, yPos)
      yPos += 10
    }
    
    yPos += 5
    
    // Page-specific content generation
    if (pageContext === 'dashboard') {
      generateDashboardReport(doc, yPos)
    } else if (pageContext === 'users') {
      generateUsersReport(doc, yPos)
    } else if (pageContext === 'donations') {
      generateDonationsReport(doc, yPos)
    }
    
    // Save PDF
    const fileName = `${pageContext}-report-${format(new Date(), 'yyyy-MM-dd')}.pdf`
    doc.save(fileName)
    
    setIsGenerating(false)
    setShowModal(false)
    setShowSuccess(true)
    setTimeout(() => setShowSuccess(false), 3000)
  }

  const generateDashboardReport = (doc: jsPDF, startY: number) => {
    let yPos = startY
    doc.setFontSize(10)
    doc.setFont(undefined, 'bold')
    doc.text('System Overview Statistics', 14, yPos)
    yPos += 10
    doc.setFont(undefined, 'normal')

    if (dashboardMetrics.totalConsumers && data) {
      doc.text(`Total Consumers: ${data.totalConsumers || 0}`, 14, yPos)
      yPos += 7
    }
    if (dashboardMetrics.totalMerchants && data) {
      doc.text(`Total Merchants: ${data.totalMerchants || 0}`, 14, yPos)
      yPos += 7
    }
    if (dashboardMetrics.totalNGOs && data) {
      doc.text(`Total NGOs Served: ${data.totalNGOs || 0}`, 14, yPos)
      yPos += 7
    }
    if (dashboardMetrics.totalOrders && data) {
      doc.text(`Total Orders Completed: ${data.totalOrders || 0}`, 14, yPos)
      yPos += 7
    }

    if (dashboardMetrics.ordersTrend || dashboardMetrics.donationTrend) {
      yPos += 5
      doc.setFont(undefined, 'bold')
      doc.text('Trends', 14, yPos)
      yPos += 7
      doc.setFont(undefined, 'normal')
      if (dashboardMetrics.ordersTrend) {
        doc.text('Orders Trend: Included in report', 14, yPos)
        yPos += 7
      }
      if (dashboardMetrics.donationTrend) {
        doc.text('Donation Trend: Included in report', 14, yPos)
        yPos += 7
      }
    }
  }

  const generateUsersReport = (doc: jsPDF, startY: number) => {
    let yPos = startY
    doc.setFontSize(10)
    doc.setFont(undefined, 'bold')
    doc.text('User Account Report', 14, yPos)
    yPos += 10

    // Apply filters
    let filteredUsers = mockUsers

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

    doc.setFont(undefined, 'normal')
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
    doc.setFont(undefined, 'bold')
    doc.text('User Details', 14, yPos)
    yPos += 7
    doc.setFont(undefined, 'normal')

    filteredUsers.slice(0, 50).forEach((user: User) => {
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

  const generateDonationsReport = (doc: jsPDF, startY: number) => {
    let yPos = startY
    doc.setFontSize(10)
    doc.setFont(undefined, 'bold')
    doc.text('Donation Delivery Report', 14, yPos)
    yPos += 10

    // Apply filters
    let filteredDonations = mockDonations.filter(d => d.status === 'completed')

    if (donationMerchantFilter !== 'all') {
      filteredDonations = filteredDonations.filter(d => d.merchantId === donationMerchantFilter)
    }

    if (donationNGOFilter !== 'all') {
      filteredDonations = filteredDonations.filter(d => d.ngoId === donationNGOFilter)
    }

    // Filter by date range (deliveryDate)
    if (startDate && endDate) {
      const start = new Date(startDate)
      const end = new Date(endDate)
      filteredDonations = filteredDonations.filter(d => {
        const deliveryDate = new Date(d.deliveryDate)
        return deliveryDate >= start && deliveryDate <= end
      })
    }

    doc.setFont(undefined, 'normal')
    doc.text(`Total Donations: ${filteredDonations.length}`, 14, yPos)
    yPos += 7
    const totalItems = filteredDonations.reduce((sum, d) => sum + (d.quantity || 0), 0)
    doc.text(`Total Items: ${totalItems}`, 14, yPos)
    yPos += 10

    doc.setFont(undefined, 'bold')
    doc.text('Donation Details', 14, yPos)
    yPos += 7
    doc.setFont(undefined, 'normal')

    filteredDonations.slice(0, 50).forEach((donation: Donation) => {
      if (yPos > 280) {
        doc.addPage()
        yPos = 20
      }
      doc.text(`ID: ${donation.id}`, 14, yPos)
      yPos += 5
      doc.text(`  Merchant: ${donation.merchantName} → NGO: ${donation.ngoName}`, 14, yPos)
      yPos += 5
      doc.text(`  Items: ${donation.items.join(', ')}`, 14, yPos)
      yPos += 5
      doc.text(`  Quantity: ${donation.quantity} | Delivery: ${format(new Date(donation.deliveryDate), 'MMM dd, yyyy')}`, 14, yPos)
      yPos += 7
    })
  }

  // Don't render button for profile page
  if (pageContext === 'profile') {
    return null
  }

  // Get unique merchants and NGOs for filters
  const uniqueMerchants = Array.from(new Set(mockDonations.map(d => ({ id: d.merchantId, name: d.merchantName }))))
  const uniqueNGOs = Array.from(new Set(mockDonations.map(d => ({ id: d.ngoId, name: d.ngoName }))))

  const modalTitles = {
    dashboard: 'Generate System Report',
    users: 'Generate User Report',
    donations: 'Generate Donation Report',
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
        onClick={() => setShowModal(true)}
        className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors"
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
                onClick={() => setShowModal(false)}
                className="text-gray-400 hover:text-gray-600"
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
                      { key: 'totalNGOs', label: 'Total NGOs Served' },
                      { key: 'totalOrders', label: 'Total Orders Completed' },
                      { key: 'ordersTrend', label: 'Orders Trend' },
                      { key: 'donationTrend', label: 'Donation Trend' },
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
                      <option value="ngo">NGOs</option>
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

              {/* Donations-specific: Filters */}
              {pageContext === 'donations' && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Merchant Filter (Optional)
                    </label>
                    <select
                      value={donationMerchantFilter}
                      onChange={(e) => setDonationMerchantFilter(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
                    >
                      <option value="all">All Merchants</option>
                      {uniqueMerchants.map((merchant) => (
                        <option key={merchant.id} value={merchant.id}>
                          {merchant.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      NGO Filter (Optional)
                    </label>
                    <select
                      value={donationNGOFilter}
                      onChange={(e) => setDonationNGOFilter(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
                    >
                      <option value="all">All NGOs</option>
                      {uniqueNGOs.map((ngo) => (
                        <option key={ngo.id} value={ngo.id}>
                          {ngo.name}
                        </option>
                      ))}
                    </select>
                  </div>
                </>
              )}
            </div>

            <div className="flex gap-3 justify-end mt-6">
              <button
                onClick={() => setShowModal(false)}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
              >
                Cancel
              </button>
              <button
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
