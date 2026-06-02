import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/shared/constants/app_constants.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/auth_profile_impact/domain/models/user_model.dart';
import 'package:savebite/features/auth_profile_impact/presentation/utils/impact_display.dart';
import 'package:savebite/features/auth_profile_impact/presentation/utils/profile_photo_picker.dart';
import 'package:savebite/features/auth_profile_impact/presentation/widgets/impact_profile_cards.dart';
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
                      _buildImpactDashboard(
                        context,
                        user.impactData,
                        isMerchant: isMerchant,
                      ),
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
        final address =
            m.address.trim().isNotEmpty ? m.address.trim() : 'Not set';
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

  /// Role-specific sustainability summary on Profile.
  Widget _buildImpactDashboard(
    BuildContext context,
    ImpactData impactData, {
    required bool isMerchant,
  }) {
    final moneySaved = impactData.moneySaved;
    final co2Reduced = impactData.co2Reduced;
    final mealsSaved = impactData.mealsSaved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push('/impact'),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingXS),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your impact',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingXS),
                        Text(
                          ImpactDisplay.profileSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Row(
            children: [
              Expanded(
                child: ImpactSnapshotMiniCard(
                  icon: Icons.cloud_outlined,
                  title: 'CO2e prevented',
                  value: ImpactDisplay.formatCo2Kg(co2Reduced),
                  accentColor: AppColors.co2Reduced,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: ImpactSnapshotMiniCard(
                  icon: Icons.payments_outlined,
                  title: ImpactDisplay.profileMoneyLabel(
                    isMerchant: isMerchant,
                  ),
                  value: ImpactDisplay.formatMoneySummary(moneySaved),
                  accentColor: AppColors.moneySaved,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          ImpactSnapshotHeroCard(
            title: 'Meals saved',
            value: '$mealsSaved',
          ),
        ],
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
