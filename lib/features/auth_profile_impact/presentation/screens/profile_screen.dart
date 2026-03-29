import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/shared/constants/app_constants.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';
import 'package:savebite/features/auth_profile_impact/presentation/utils/profile_photo_picker.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';

/// Profile Screen
///
/// Displays user profile information from AuthProvider, impact dashboard, and settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        final isMerchant = user?.role == UserRole.merchant;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: const AppBackButton(),
            title: Text('Profile', style: AppTypography.h3),
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppColors.background,
          ),
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(context, user),
                      const SizedBox(height: AppConstants.paddingL),
                      _buildImpactDashboard(user.impactData),
                      const SizedBox(height: AppConstants.paddingL),
                      if (isMerchant) ...[
                        _buildMerchantStoreInfoSection(context, user),
                        const SizedBox(height: AppConstants.paddingL),
                        _buildMerchantActionsSection(context, authProvider),
                      ] else ...[
                      _buildMenuSection(context, authProvider),
                      ],
                      const SizedBox(height: AppConstants.paddingXL),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: AppConstants.paddingS),
          child,
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: card,
    );
  }

  Widget _buildKVRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantStoreInfoSection(BuildContext context, UserModel user) {
    final merchantId = user.merchantId ?? user.id;
    final merchantProvider = context.read<MerchantProvider>();

    return StreamBuilder<MerchantModel?>(
      stream: merchantProvider.watchMerchant(merchantId),
      builder: (context, snapshot) {
        final m = snapshot.data;
        if (m == null) {
          return _buildSectionCard(
            title: 'Store Information',
            onTap: () => context.push('/merchant-store-setup?onboarding=false'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your store profile is not set up yet.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/merchant-store-setup?onboarding=false'),
                    child: const Text('Create Store Profile'),
                  ),
                ),
              ],
            ),
          );
        }
        final name = m.name.trim().isNotEmpty ? m.name.trim() : 'Not set';
        final address = m.address.trim().isNotEmpty ? m.address.trim() : 'Not set';
        final phone =
            m.phoneNumber.trim().isNotEmpty ? m.phoneNumber.trim() : 'Not set';
        final desc =
            m.description.trim().isNotEmpty ? m.description.trim() : 'Not set';

        return _buildSectionCard(
          title: 'Store Information',
          onTap: () => context.push('/merchant-store-setup?onboarding=false'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKVRow('Shop Name', name),
              _buildKVRow('Address', address),
              _buildKVRow('Phone', phone),
              _buildKVRow('About', desc),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMerchantActionsSection(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          onTap: () => context.push('/edit-profile'),
        ),
        const SizedBox(height: AppConstants.paddingM),
        _buildLogoutButton(context, authProvider),
      ],
    );
  }

  /// Header: User Profile Picture (Circle Avatar) and Name
  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    final profileImage = user.profileImage;
    final name = user.name;
    final email = user.email;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => pickAndUploadProfilePhoto(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
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
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: profileImage != null && profileImage.isNotEmpty
                      ? Image.network(
                          profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildProfilePlaceholder(),
                        )
                      : _buildProfilePlaceholder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            name.isNotEmpty ? name : 'User',
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            email,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            'Tap photo to change',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.person,
        size: AppConstants.iconXL,
        color: AppColors.primary,
      ),
    );
  }

  /// Impact Dashboard (Image 2 Style)
  Widget _buildImpactDashboard(ImpactData impactData) {
    final moneySaved = impactData.moneySaved;
    final co2Reduced = impactData.co2Reduced;
    final mealsSaved = impactData.mealsSaved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your impact',
            style: AppTypography.h2.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Money saved',
                  value:
                      '${AppConstants.currencySymbol} ${moneySaved.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: _buildMetricTile(
                  label: 'CO2e saved',
                  value: '${co2Reduced.toStringAsFixed(0)} kg',
                  icon: Icons.cloud_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          _buildHeroTile(mealsSaved),
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
          Icon(
            icon,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXS),
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

  /// Hero Tile Widget (Meals saved with image)
  Widget _buildHeroTile(int mealsSaved) {
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
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meals\nsaved',
                      style: AppTypography.h5.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      '$mealsSaved',
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
  Widget _buildMenuSection(BuildContext context, AuthProvider authProvider) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          onTap: () => context.push('/edit-profile'),
        ),
        _buildMenuItem(
          icon: Icons.payment,
          title: 'Payment Methods',
          onTap: () => context.push('/payment-methods'),
        ),
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(height: AppConstants.paddingM),
        _buildLogoutButton(context, authProvider),
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
  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(context, authProvider),
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
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
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
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) context.go('/landing');
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

