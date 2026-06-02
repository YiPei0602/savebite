import { useEffect, useMemo, useState } from 'react'
import { Search, Trash2, UserCheck, UserX, Eye } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { format } from 'date-fns'
import { GenerateReportButton } from '@/shared/components/Common/GenerateReportButton'
import type { UserRecord } from '@/shared/types/models'
import {
  deleteUser,
  subscribeUsers,
  updateUserStatus,
} from '@/features/users/api/usersApi'

export function UsersListPage() {
  const navigate = useNavigate()
  const [searchQuery, setSearchQuery] = useState('')
  const [roleFilter, setRoleFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [selectedUser, setSelectedUser] = useState<UserRecord | null>(null)
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [showSuccessMessage, setShowSuccessMessage] = useState('')
  const [actionError, setActionError] = useState<string | null>(null)
  const [pendingActionUserId, setPendingActionUserId] = useState<string | null>(null)
  const [deletePending, setDeletePending] = useState(false)
  const [users, setUsers] = useState<UserRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const showActionError = (e: unknown) => {
    const msg = e instanceof Error ? e.message : String(e)
    setActionError(msg)
    window.alert(`Action failed: ${msg}`)
  }

  const clearActionFeedbackSoon = (success: string) => {
    setShowSuccessMessage(success)
    setTimeout(() => setShowSuccessMessage(''), 4000)
  }

  useEffect(() => {
    setLoading(true)
    setError(null)
    const unsub = subscribeUsers(
      (u) => {
        setUsers(u)
        setLoading(false)
      },
      (e) => {
        setError(e instanceof Error ? e.message : String(e))
        setLoading(false)
      },
    )
    return () => {
      unsub()
    }
  }, [])

  // Filter users
  const filteredUsers = useMemo(() => {
    let list = users

    if (roleFilter !== 'all') {
      list = list.filter((u) => u.role === roleFilter)
    }

    if (statusFilter !== 'all') {
      list = list.filter((u) => u.status === statusFilter)
    }

    // Apply search
    if (searchQuery) {
      list = list.filter(
        user =>
          user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          user.email.toLowerCase().includes(searchQuery.toLowerCase())
      )
    }

    return list
  }, [searchQuery, roleFilter, statusFilter, users])

  const handleViewDetails = (user: UserRecord) => {
    navigate(`/users/${user.id}`)
  }

  const handleActivate = async (user: UserRecord) => {
    setActionError(null)
    setPendingActionUserId(user.id)
    try {
      await updateUserStatus(user.id, 'active')
      setUsers((prev) =>
        prev.map((u) => (u.id === user.id ? { ...u, status: 'active' } : u)),
      )
      clearActionFeedbackSoon(`User ${user.name} activated successfully`)
    } catch (e) {
      showActionError(e)
    } finally {
      setPendingActionUserId(null)
    }
  }

  const handleSuspend = async (user: UserRecord) => {
    setActionError(null)
    setPendingActionUserId(user.id)
    try {
      await updateUserStatus(user.id, 'suspended')
      setUsers((prev) =>
        prev.map((u) => (u.id === user.id ? { ...u, status: 'suspended' } : u)),
      )
      clearActionFeedbackSoon(`User ${user.name} suspended successfully`)
    } catch (e) {
      showActionError(e)
    } finally {
      setPendingActionUserId(null)
    }
  }

  const handleDeleteClick = (user: UserRecord) => {
    setSelectedUser(user)
    setShowDeleteModal(true)
  }

  const handleDeleteConfirm = async () => {
    if (!selectedUser) return
    setActionError(null)
    setDeletePending(true)
    try {
      await deleteUser(selectedUser.id)
      setUsers((prev) => prev.filter((u) => u.id !== selectedUser.id))
      clearActionFeedbackSoon(`User ${selectedUser.name} deleted successfully`)
      setShowDeleteModal(false)
      setSelectedUser(null)
    } catch (e) {
      showActionError(e)
    } finally {
      setDeletePending(false)
    }
  }

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-green-100 text-green-800',
      suspended: 'bg-red-100 text-red-800',
      inactive: 'bg-gray-100 text-gray-800',
    }
    return (
      <span className={`px-2 py-1 text-xs font-medium rounded-full ${styles[status as keyof typeof styles]}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    )
  }

  const getRoleBadge = (role: string) => {
    const styles: Record<string, string> = {
      consumer: 'bg-blue-100 text-blue-800',
      merchant: 'bg-purple-100 text-purple-800',
    }
    const cls = styles[role] ?? 'bg-gray-100 text-gray-800'
    return (
      <span className={`px-2 py-1 text-xs font-medium rounded-full ${cls}`}>
        {role.charAt(0).toUpperCase() + role.slice(1)}
      </span>
    )
  }

  return (
    <div className="space-y-6">
      {loading && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          Loading users…
        </div>
      )}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}
      {actionError && (
        <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg">
          {actionError}
          <button
            type="button"
            className="ml-3 text-sm underline"
            onClick={() => setActionError(null)}
          >
            Dismiss
          </button>
        </div>
      )}
      {/* Success Message */}
      {showSuccessMessage && (
        <div className="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg">
          {showSuccessMessage}
        </div>
      )}

      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Manage User Accounts</h1>
          <p className="text-gray-600 mt-1">Search, filter, and manage users</p>
        </div>
        <GenerateReportButton pageContext="users" data={filteredUsers} />
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
                placeholder="Search by name or email..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              />
            </div>
          </div>

          {/* Role Filter */}
          <div>
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
            >
              <option value="all">All Roles</option>
              <option value="consumer">Consumer</option>
              <option value="merchant">Merchant</option>
            </select>
          </div>

          {/* Status Filter */}
          <div>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="suspended">Suspended</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Email
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Role
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Created
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                    No users found
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{user.name}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-500">{user.email}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">{getRoleBadge(user.role)}</td>
                    <td className="px-6 py-4 whitespace-nowrap">{getStatusBadge(user.status)}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {format(new Date(user.createdAt), 'MMM dd, yyyy')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleViewDetails(user)}
                          className="text-blue-600 hover:text-blue-900"
                          title="View Details"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        {user.status === 'active' ? (
                          <button
                            type="button"
                            disabled={pendingActionUserId === user.id}
                            onClick={() => handleSuspend(user)}
                            className="text-yellow-600 hover:text-yellow-900 disabled:opacity-40"
                            title="Suspend"
                          >
                            <UserX className="w-4 h-4" />
                          </button>
                        ) : (
                          <button
                            type="button"
                            disabled={pendingActionUserId === user.id}
                            onClick={() => handleActivate(user)}
                            className="text-green-600 hover:text-green-900 disabled:opacity-40"
                            title="Activate"
                          >
                            <UserCheck className="w-4 h-4" />
                          </button>
                        )}
                        <button
                          type="button"
                          disabled={pendingActionUserId === user.id}
                          onClick={() => handleDeleteClick(user)}
                          className="text-red-600 hover:text-red-900 disabled:opacity-40"
                          title="Delete"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteModal && selectedUser && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Delete User</h3>
            <p className="text-gray-600 mb-6">
              Are you sure you want to delete <strong>{selectedUser.name}</strong>? This action cannot be undone.
            </p>
            <div className="flex gap-3 justify-end">
              <button
                type="button"
                disabled={deletePending}
                onClick={() => {
                  setShowDeleteModal(false)
                  setSelectedUser(null)
                }}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={deletePending}
                onClick={handleDeleteConfirm}
                className="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                {deletePending ? 'Deleting…' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
