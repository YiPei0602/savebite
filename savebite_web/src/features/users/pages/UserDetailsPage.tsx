import { useParams } from 'react-router-dom'
import { Typography, Box } from '@mui/material'

export function UserDetailsPage() {
  const { id } = useParams<{ id: string }>()

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        User Details
      </Typography>
      <Typography variant="body1" color="text.secondary">
        User ID: {id}
      </Typography>
      {/* TODO: Implement user details */}
    </Box>
  )
}

