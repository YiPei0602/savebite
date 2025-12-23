import { Typography, Box } from '@mui/material'

export function UsersListPage() {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        User Management
      </Typography>
      <Typography variant="body1" color="text.secondary">
        Manage consumers, merchants, and NGOs
      </Typography>
      {/* TODO: Implement user table */}
    </Box>
  )
}

