import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Profile Screen
/// 
/// Displays user profile information, impact dashboard, and settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.h3),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header: Profile Picture and Name
            _buildProfileHeader(),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // Impact Dashboard (Crucial Feature)
            _buildImpactDashboard(),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // Menu Options
            _buildMenuSection(context),
            
            const SizedBox(height: AppConstants.paddingXL),
          ],
        ),
      ),
    );
  }

  /// Header: User Profile Picture (Circle Avatar) and Name
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        children: [
          // Circle Avatar (Profile Picture)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(
                Icons.person,
                size: AppConstants.iconXL,
                color: AppColors.primary,
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingM),
          
          // User Name
          Text(
            'John Doe',
            style: AppTypography.h2,
          ),
          
          const SizedBox(height: AppConstants.paddingXS),
          
          // Email
          Text(
            'john.doe@example.com',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Impact Dashboard (Crucial Feature)
  /// Dark Green background with 3 statistics in white text
  Widget _buildImpactDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        decoration: BoxDecoration(
          // Dark Green gradient based on #00A86B
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,      // Darker green
              AppColors.primary,          // #00A86B
              AppColors.primaryDark,      // Darker green
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Dashboard Title
            Row(
              children: [
                Icon(
                  Icons.eco,
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  'Your Impact',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // 3 Statistics in a Row (White Text)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Meals Saved
                _buildImpactStat(
                  icon: Icons.restaurant,
                  value: '12',
                  label: 'Meals Saved',
                ),
                
                // Divider
                Container(
                  height: 60,
                  width: 1,
                  color: AppColors.textOnPrimary.withOpacity(0.3),
                ),
                
                // 2. Money Saved
                _buildImpactStat(
                  icon: Icons.savings,
                  value: 'RM 145',
                  label: 'Money Saved',
                ),
                
                // Divider
                Container(
                  height: 60,
                  width: 1,
                  color: AppColors.textOnPrimary.withOpacity(0.3),
                ),
                
                // 3. CO2 Prevented
                _buildImpactStat(
                  icon: Icons.co2,
                  value: '5kg',
                  label: 'CO₂ Prevented',
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // View Details Button
            TextButton(
              onPressed: () {
                // TODO: Navigate to detailed impact dashboard
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Detailed Impact',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingXS),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.textOnPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Impact Statistic Widget
  Widget _buildImpactStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Icon
          Icon(
            icon,
            color: AppColors.textOnPrimary,
            size: 28,
          ),
          
          const SizedBox(height: AppConstants.paddingS),
          
          // Value (White Text)
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingXS),
          
          // Label (White Text)
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textOnPrimary.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// Menu Options Section
  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        // Edit Profile
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          onTap: () {
            context.push('/edit-profile');
          },
        ),
        
        // Payment Methods
        _buildMenuItem(
          icon: Icons.payment,
          title: 'Payment Methods',
          onTap: () {
            context.push('/payment-methods');
          },
        ),
        
        // Notifications
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () {
            context.push('/notifications');
          },
        ),
        
        const SizedBox(height: AppConstants.paddingM),
        
        // Log Out
        _buildLogoutButton(context),
      ],
    );
  }

  /// Menu Item Tile
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppConstants.paddingS),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  /// Log Out Button
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: OutlinedButton(
        onPressed: () {
          _showLogoutDialog(context);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          minimumSize: const Size(double.infinity, AppConstants.buttonHeightM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              'Log Out',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Out', style: AppTypography.h4),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Log Out', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );
  }
}
