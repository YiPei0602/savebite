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
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
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
            child: ClipOval(
              child: Container(
                width: 100,
                height: 100,
                color: AppColors.surfaceVariant,
                child: Image.asset(
                  'assets/images/suzy.png',
                  fit: BoxFit.cover,
                  alignment: Alignment(0, -0.3), // Shift image down to show more of lower part
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: AppConstants.iconXL,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingM),
          
          // User Name
          Text(
            'Evelyn Liu',
            style: AppTypography.h2,
          ),
          
          const SizedBox(height: AppConstants.paddingXS),
          
          // Email
          Text(
            'evelyn922@gmail.com',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Impact Dashboard (Image 2 Style)
  /// Clean layout with 2 metric tiles + 1 hero tile with bag image
  Widget _buildImpactDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Your impact',
            style: AppTypography.h2.copyWith(
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingM),
          
          // Row of 2 metric tiles
          Row(
            children: [
              // Money Saved Tile
              Expanded(
                child: _buildMetricTile(
                  label: 'Money saved',
                  value: 'RM 581',
                  icon: Icons.payments_outlined,
                ),
              ),
              
              const SizedBox(width: AppConstants.paddingM),
              
              // CO2e Saved Tile
              Expanded(
                child: _buildMetricTile(
                  label: 'CO2e saved',
                  value: '140 kg',
                  icon: Icons.cloud_outlined,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.paddingM),
          
          // Hero Tile - Surprise Bags Saved
          _buildHeroTile(),
        ],
      ),
    );
  }

  /// Metric Tile Widget (Money saved, CO2e saved)
  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Icon(
            icon,
            color: AppColors.primary,
            size: 32,
          ),
          
          const SizedBox(height: AppConstants.paddingS),
          
          // Label
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingXS),
          
          // Value
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Hero Tile Widget (Surprise Bags saved with image)
  Widget _buildHeroTile() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Row(
          children: [
            // Left: Bag Image/Icon
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern (optional decorative circles)
                    Positioned(
                      top: -20,
                      left: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textOnPrimary.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      right: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textOnPrimary.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Shopping bag icon
                    Center(
                      child: Icon(
                        Icons.shopping_bag,
                        size: 72,
                        color: AppColors.textOnPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Right: Text Content
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Text(
                      'Meals\nsaved',
                      style: AppTypography.h5.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.paddingS),
                    
                    // Value
                    Text(
                      '53',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
