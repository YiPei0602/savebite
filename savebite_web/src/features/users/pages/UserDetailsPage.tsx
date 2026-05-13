import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Edit, Save, X } from 'lucide-react'
import { format } from 'date-fns'
import type { UserRecord, UserRole } from '@/shared/types/models'
import { getUserById, updateUser } from '@/features/users/api/usersApi'

export function UserDetailsPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [user, setUser] = useState<UserRecord | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    role: 'consumer' as UserRole,
  })
  const [showSuccessMessage, setShowSuccessMessage] = useState('')
  const [saveError, setSaveError] = useState<string | null>(null)
  const [savePending, setSavePending] = useState(false)

  useEffect(() => {
    let alive = true
    if (!id) return
    ;(async () => {
      try {
        setLoading(true)
        setError(null)
        const u = await getUserById(id)
        if (!alive) return
        setUser(u)
        setFormData({
          name: u?.name ?? '',
          email: u?.email ?? '',
          role: (u?.role ?? 'consumer') as UserRole,
        })
      } catch (e) {
        if (!alive) return
        setError(e instanceof Error ? e.message : String(e))
      } finally {
        if (!alive) return
        setLoading(false)
      }
    })()
    return () => {
      alive = false
    }
  }, [id])

  if (loading) {
    return <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">Loading user…</div>
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg">
        {error}
      </div>
    )
  }

  if (!user) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">User not found</p>
        <button
          onClick={() => navigate('/users')}
          className="mt-4 text-primary hover:underline"
        >
          Back to Users
        </button>
      </div>
    )
  }

  const handleSave = async () => {
    setSaveError(null)
    setSavePending(true)
    try {
      await updateUser(user.id, {
        name: formData.name,
        email: formData.email,
        role: formData.role,
      })
      setUser((prev) =>
        prev
          ? {
              ...prev,
              name: formData.name,
              email: formData.email,
              role: formData.role,
            }
          : prev,
      )
      setShowSuccessMessage('User updated successfully')
      setIsEditing(false)
      setTimeout(() => setShowSuccessMessage(''), 4000)
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e)
      setSaveError(msg)
      window.alert(`Update failed: ${msg}`)
    } finally {
      setSavePending(false)
    }
  }

  const handleCancel = () => {
    setFormData({
      name: user.name,
      email: user.email,
      role: user.role,
    })
    setSaveError(null)
    setIsEditing(false)
  }

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-green-100 text-green-800',
      suspended: 'bg-red-100 text-red-800',
      inactive: 'bg-gray-100 text-gray-800',
    }
    return (
      <span className={`px-3 py-1 text-sm font-medium rounded-full ${styles[status as keyof typeof styles]}`}>
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
      <span className={`px-3 py-1 text-sm font-medium rounded-full ${cls}`}>
        {role.charAt(0).toUpperCase() + role.slice(1)}
      </span>
    )
  }

  return (
    <div className="space-y-6">
      {/* Success Message */}
      {showSuccessMessage && (
        <div className="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg">
          {showSuccessMessage}
        </div>
      )}
      {saveError && (
        <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg">
          {saveError}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate('/users')}
            className="p-2 hover:bg-gray-100 rounded-lg"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">User Details</h1>
            <p className="text-gray-600 mt-1">View and edit user information</p>
          </div>
        </div>
        {!isEditing ? (
          <button
            onClick={() => setIsEditing(true)}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark"
          >
            <Edit className="w-4 h-4" />
            Edit
          </button>
        ) : (
          <div className="flex gap-2">
            <button
              onClick={handleCancel}
              className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
            >
              <X className="w-4 h-4" />
              Cancel
            </button>
            <button
              type="button"
              disabled={savePending}
              onClick={handleSave}
              className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              {savePending ? 'Saving…' : 'Save'}
            </button>
          </div>
        )}
      </div>

      {/* User Details Card */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Name</label>
            {isEditing ? (
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              />
            ) : (
              <p className="text-gray-900">{user.name}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
            {isEditing ? (
              <input
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              />
            ) : (
              <p className="text-gray-900">{user.email}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Role</label>
            {isEditing ? (
              <select
                value={formData.role}
                onChange={(e) =>
                  setFormData({ ...formData, role: e.target.value as UserRole })
                }
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent"
              >
                <option value="consumer">Consumer</option>
                <option value="merchant">Merchant</option>
              </select>
            ) : (
              getRoleBadge(user.role)
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
            {getStatusBadge(user.status)}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Created At</label>
            <p className="text-gray-900">{format(new Date(user.createdAt), 'MMM dd, yyyy HH:mm')}</p>
          </div>
        </div>
      </div>
    </div>
  )
}
