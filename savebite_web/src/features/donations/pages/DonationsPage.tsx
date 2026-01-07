import { useState, useMemo } from 'react'
import { Search } from 'lucide-react'
import { mockDonations, getDonationsByNGO, getDonationsByDateRange } from '@/shared/data/mockData'
import { format } from 'date-fns'
import { GenerateReportButton } from '@/shared/components/Common/GenerateReportButton'

export function DonationsPage() {
  const [searchQuery, setSearchQuery] = useState('')
  const [ngoFilter, setNgoFilter] = useState('all')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')

  // Get unique NGOs
  const uniqueNGOs = useMemo(() => {
    const ngos = new Set(mockDonations.map(d => d.ngoName))
    return Array.from(ngos)
  }, [])

  // Filter donations
  const filteredDonations = useMemo(() => {
    let donations = mockDonations

    // Apply NGO filter
    if (ngoFilter !== 'all') {
      const ngo = mockDonations.find(d => d.ngoName === ngoFilter)
      if (ngo) {
        donations = getDonationsByNGO(ngo.ngoId)
      }
    }

    // Apply date range filter
    if (startDate && endDate) {
      donations = getDonationsByDateRange(startDate, endDate)
    }

    // Apply search
    if (searchQuery) {
      donations = donations.filter(
        donation =>
          donation.merchantName.toLowerCase().includes(searchQuery.toLowerCase()) ||
          donation.ngoName.toLowerCase().includes(searchQuery.toLowerCase()) ||
          donation.items.some(item => item.toLowerCase().includes(searchQuery.toLowerCase()))
      )
    }

    return donations.filter(d => d.status === 'completed')
  }, [searchQuery, ngoFilter, startDate, endDate])


  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Donation Records</h1>
          <p className="text-gray-600 mt-1">View and manage successful donations</p>
        </div>
        <GenerateReportButton pageContext="donations" data={filteredDonations} />
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {/* Search */}
          <div className="md:col-span-2">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Search donations..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              />
            </div>
          </div>

          {/* NGO Filter */}
          <div>
            <select
              value={ngoFilter}
              onChange={(e) => setNgoFilter(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
            >
              <option value="all">All NGOs</option>
              {uniqueNGOs.map(ngo => (
                <option key={ngo} value={ngo}>{ngo}</option>
              ))}
            </select>
          </div>

          {/* Date Range */}
          <div className="flex gap-2">
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              placeholder="Start Date"
            />
          </div>
        </div>
        {startDate && (
          <div className="mt-4">
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="w-full md:w-auto px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              placeholder="End Date"
            />
          </div>
        )}
      </div>

      {/* Donations Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Donation ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Merchant
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  NGO
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Items
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Quantity
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Delivery Date
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredDonations.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                    No donations found
                  </td>
                </tr>
              ) : (
                filteredDonations.map((donation) => (
                  <tr key={donation.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {donation.id}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {donation.merchantName}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {donation.ngoName}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {donation.items.join(', ')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {donation.quantity}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {format(new Date(donation.deliveryDate), 'MMM dd, yyyy')}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
