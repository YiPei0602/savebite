import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/features/donations/state/providers/donation_provider.dart';
import 'package:savebite/shared/constants/app_constants.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';

/// Donation Prompt Screen
///
/// Automated prompt for merchants to donate unsold surplus food.
class DonationPromptScreen extends StatefulWidget {
  const DonationPromptScreen({super.key});

  @override
  State<DonationPromptScreen> createState() => _DonationPromptScreenState();
}

class _DonationPromptScreenState extends State<DonationPromptScreen> {
  String? _selectedNGO;

  bool _isLoadingNgos = false;
  List<Map<String, String>> _ngos = [];

  // Placeholder until wired to real merchant inventory/orders
  final List<Map<String, dynamic>> _unsoldItems = [];

  @override
  void initState() {
    super.initState();
    _loadNgos();
  }

  Future<void> _loadNgos() async {
    setState(() {
      _isLoadingNgos = true;
    });
    final ngos = await context.read<DonationProvider>().getAvailableNGOs();
    if (!mounted) return;
    setState(() {
      _ngos = ngos;
      _isLoadingNgos = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _unsoldItems.fold<double>(
      0,
      (sum, item) => sum + (item['value'] as double),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                children: [
                  _buildDonationMessage(totalValue),
                  const SizedBox(height: 24),
                  _buildUnsoldItems(),
                  const SizedBox(height: 24),
                  _buildNGOSelection(),
                  const SizedBox(height: 24),
                  _buildImpactPreview(),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppBackButton(
                color: Colors.white,
                fallbackRoute: '/merchant-dashboard',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingL,
              0,
              AppConstants.paddingL,
              AppConstants.paddingL,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donate Unsold Food',
                        style: AppTypography.h3.copyWith(color: Colors.white),
                      ),
                      Text(
                        'Help reduce food waste',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationMessage(double totalValue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.green.shade700,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'You have unsold items worth RM ${totalValue.toStringAsFixed(2)}',
            style: AppTypography.h5.copyWith(
              color: Colors.green.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Instead of throwing them away, consider donating to help those in need!',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnsoldItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unsold Items', style: AppTypography.h4),
        const SizedBox(height: 12),
        if (_unsoldItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.textTertiary.withOpacity(0.2),
              ),
            ),
            child: Text(
              'No unsold items available right now.',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ..._unsoldItems.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.textTertiary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fastfood,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['name'],
                    style: AppTypography.bodyMedium,
                  ),
                ),
                Text(
                  'x${item['quantity']}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNGOSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select NGO', style: AppTypography.h4),
        const SizedBox(height: 12),
        if (_isLoadingNgos)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_ngos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: AppColors.textTertiary.withOpacity(0.2),
              ),
            ),
            child: Text(
              'No NGOs available yet.',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ..._ngos.map((ngo) {
          final isSelected = _selectedNGO == ngo['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedNGO = ngo['id'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Colors.green.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ngo['name'] ?? '', style: AppTypography.h5),
                        const SizedBox(height: 4),
                        Text(
                          ngo['description'] ?? '',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImpactPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            'Impact Preview',
            style: AppTypography.h4.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Impact tracking will appear here once donations are wired to real inventory and NGO pickup flows.',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _ImpactStat(value: '—', label: 'Meals\nDonated'),
              _ImpactStat(value: '—', label: 'CO₂\nSaved'),
              _ImpactStat(value: '—', label: 'People\nHelped'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Not Now',
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_selectedNGO != null && _unsoldItems.isNotEmpty)
                  ? _handleDonate
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Text('Confirm Donation', style: AppTypography.buttonMedium),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDonate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Thank You!'),
          ],
        ),
        content: const Text(
          'Your donation has been confirmed. The NGO will be notified for pickup.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Donation confirmed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleReject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Donation?'),
        content: const Text(
          'Are you sure you want to skip donating these items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final String value;
  final String label;

  const _ImpactStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

