import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

/// Donation Prompt Screen
/// 
/// Automated prompt for merchants to donate unsold surplus food
class DonationPromptScreen extends StatefulWidget {
  const DonationPromptScreen({super.key});

  @override
  State<DonationPromptScreen> createState() => _DonationPromptScreenState();
}

class _DonationPromptScreenState extends State<DonationPromptScreen> {
  String? _selectedNGO;
  
  final List<Map<String, dynamic>> _ngos = [
    {
      'id': '1',
      'name': 'Food Bank Malaysia',
      'description': 'Feeding the urban poor',
      'icon': Icons.food_bank,
    },
    {
      'id': '2',
      'name': 'Kechara Soup Kitchen',
      'description': 'Serving the homeless',
      'icon': Icons.volunteer_activism,
    },
    {
      'id': '3',
      'name': 'Yayasan Chow Kit',
      'description': 'Supporting underprivileged children',
      'icon': Icons.child_care,
    },
  ];

  final List<Map<String, dynamic>> _unsoldItems = [
    {
      'name': 'Surplus Pastry Box',
      'quantity': 2,
      'value': 25.00,
    },
    {
      'name': 'Mixed Rice Bowl',
      'quantity': 1,
      'value': 9.00,
    },
  ];

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
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                children: [
                  // Donation Message
                  _buildDonationMessage(totalValue),
                  const SizedBox(height: 24),
                  
                  // Unsold Items
                  _buildUnsoldItems(),
                  const SizedBox(height: 24),
                  
                  // Select NGO
                  _buildNGOSelection(),
                  const SizedBox(height: 24),
                  
                  // Impact Preview
                  _buildImpactPreview(),
                ],
              ),
            ),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        Text(
          'Unsold Items',
          style: AppTypography.h4,
        ),
        const SizedBox(height: 12),
        ..._unsoldItems.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.textTertiary.withOpacity(0.2)),
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
        )),
      ],
    );
  }

  Widget _buildNGOSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select NGO',
          style: AppTypography.h4,
        ),
        const SizedBox(height: 12),
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
                      ngo['icon'],
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ngo['name'],
                          style: AppTypography.h5,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ngo['description'],
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
                      decoration: BoxDecoration(
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
          Icon(
            Icons.eco,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Your Impact',
            style: AppTypography.h4.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildImpactStat('3', 'Meals\nDonated'),
              _buildImpactStat('2kg', 'CO₂\nSaved'),
              _buildImpactStat('3', 'People\nHelped'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String value, String label) {
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
              onPressed: () => _handleReject(),
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
              onPressed: _selectedNGO != null ? _handleDonate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Text(
                'Confirm Donation',
                style: AppTypography.buttonMedium,
              ),
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
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Thank You!'),
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
