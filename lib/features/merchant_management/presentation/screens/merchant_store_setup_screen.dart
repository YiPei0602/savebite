import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/shared/utils/malaysia_phone_utils.dart';
import 'package:savebite/shared/utils/merchant_schedule_utils.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';
import 'package:savebite/shared/widgets/places_autocomplete_field.dart';

/// Merchant Store Setup (required after merchant signup).
///
/// Required: shop name, address, phone.
class MerchantStoreSetupScreen extends StatefulWidget {
  const MerchantStoreSetupScreen({
    super.key,
    this.isOnboarding = false,
  });

  final bool isOnboarding;

  @override
  State<MerchantStoreSetupScreen> createState() =>
      _MerchantStoreSetupScreenState();
}

class _MerchantStoreSetupScreenState extends State<MerchantStoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _didInit = false;
  bool _saving = false;

  final Set<int> _operatingDays = <int>{}; // 1=Mon ... 7=Sun
  TimeOfDay? _opening;
  TimeOfDay? _closing;

  /// From Places selection; merged with [MerchantModel] on save.
  double? _shopLat;
  double? _shopLng;
  String? _shopPlaceId;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _hasValidShopCoords(MerchantModel? existing) {
    final lat = _shopLat ?? existing?.latitude;
    final lng = _shopLng ?? existing?.longitude;
    return lat != null && lng != null;
  }

  bool _isComplete(MerchantModel? existing) {
    return _nameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _hasValidShopCoords(existing) &&
        normalizeMalaysianMobileToE164(_phoneController.text.trim()) != null &&
        _operatingDays.isNotEmpty &&
        _opening != null &&
        _closing != null;
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'Not set';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickOpeningTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _opening ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _opening = picked);
  }

  Future<void> _pickClosingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _closing ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _closing = picked);
  }

  Widget _buildOperatingDaysChips() {
    const labels = <int, String>{
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: labels.entries.map((e) {
        final selected = _operatingDays.contains(e.key);
        return FilterChip(
          label: Text(e.value),
          selected: selected,
          onSelected: (v) => setState(() {
            if (v) {
              _operatingDays.add(e.key);
            } else {
              _operatingDays.remove(e.key);
            }
          }),
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          labelStyle: AppTypography.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildOperatingHoursPicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _saving ? null : _pickOpeningTime,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opening',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(_opening),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: InkWell(
            onTap: _saving ? null : _pickClosingTime,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Closing',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(_closing),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoursHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Overnight hours are OK (e.g. open 20:00, close 02:00). Times use Malaysia (GMT+8).',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Future<void> _save(String merchantId, MerchantModel? existing) async {
    if (!_formKey.currentState!.validate()) return;
    if (_operatingDays.isEmpty || _opening == null || _closing == null) return;

    String fmtHhMm(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final openM = merchantTimeToMinutes(fmtHhMm(_opening!));
    final closeM = merchantTimeToMinutes(fmtHhMm(_closing!));
    if (openM == closeM) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening and closing cannot be the same time.'),
        ),
      );
      return;
    }

    final lat = _shopLat ?? existing?.latitude;
    final lng = _shopLng ?? existing?.longitude;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your shop address from the search suggestions.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final email = context.read<AuthProvider>().currentUser?.email ?? '';
      final phoneE164 =
          normalizeMalaysianMobileToE164(_phoneController.text.trim())!;

      final merchant = MerchantModel(
        id: merchantId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: phoneE164,
        email: email,
        description: _descriptionController.text.trim(),
        imageUrl: existing?.imageUrl ?? '',
        categories: existing?.categories ?? const <String>[],
        latitude: lat,
        longitude: lng,
        googlePlaceId: _shopPlaceId ?? existing?.googlePlaceId,
        isOpen: existing?.isOpen ?? true,
        openingTime: existing?.openingTime,
        closingTime: existing?.closingTime,
        operatingDays: _operatingDays.toList()..sort(),
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final merchantWithHours = merchant.copyWith(
        openingTime: fmtHhMm(_opening!),
        closingTime: fmtHhMm(_closing!),
      );

      final ok =
          await context.read<MerchantProvider>().updateMerchant(merchantWithHours);
      if (!ok) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save store profile. Please try again.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _saving = false);

      if (widget.isOnboarding) {
        context.go('/merchant-dashboard');
      } else {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/merchant-profile');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      debugPrint('[MerchantStoreSetup] save failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save store profile. Please try again.')),
      );
    }
  }

  InputDecoration _decoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: AppTypography.inputHint.copyWith(color: const Color(0xFF60646C)),
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.borderActive, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final merchantId = auth.currentUser?.merchantId ?? auth.currentUser?.id;
    if (merchantId == null || merchantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Merchant session missing')),
      );
    }

    final merchantProvider = context.read<MerchantProvider>();

    return StreamBuilder<MerchantModel?>(
      stream: merchantProvider.watchMerchant(merchantId),
      builder: (context, snapshot) {
        final existing = snapshot.data;
        // Only init when we have a definitive snapshot (not still loading).
        // Otherwise _didInit gets set on first build when existing is null,
        // and we never pre-fill when real data arrives.
        if (!_didInit && snapshot.connectionState != ConnectionState.waiting) {
          _didInit = true;
          if (existing != null) {
            final n = existing.name.trim();
            _nameController.text =
                (n.isEmpty || n.toLowerCase() == 'your store') ? '' : existing.name;
            _addressController.text = existing.address;
            _shopLat = existing.latitude;
            _shopLng = existing.longitude;
            _shopPlaceId = existing.googlePlaceId;
            _phoneController.text = existing.phoneNumber.isNotEmpty
                ? existing.phoneNumber
                : (auth.currentUser?.phoneNumber ?? '');
            _descriptionController.text = existing.description;
            _operatingDays
              ..clear()
              ..addAll(existing.operatingDays);
            if (existing.openingTime != null &&
                RegExp(r'^\d{2}:\d{2}$').hasMatch(existing.openingTime!)) {
              final p = existing.openingTime!.split(':');
              _opening = TimeOfDay(
                hour: int.tryParse(p[0]) ?? TimeOfDay.now().hour,
                minute: int.tryParse(p[1]) ?? TimeOfDay.now().minute,
              );
            }
            if (existing.closingTime != null &&
                RegExp(r'^\d{2}:\d{2}$').hasMatch(existing.closingTime!)) {
              final p = existing.closingTime!.split(':');
              _closing = TimeOfDay(
                hour: int.tryParse(p[0]) ?? TimeOfDay.now().hour,
                minute: int.tryParse(p[1]) ?? TimeOfDay.now().minute,
              );
            }
          } else {
            _phoneController.text = auth.currentUser?.phoneNumber ?? '';
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: widget.isOnboarding
                ? null
                : const AppBackButton(color: AppColors.textPrimary),
            title: Text(
              widget.isOnboarding ? 'Set Up Your Store' : 'Store Profile',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isOnboarding)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppConstants.paddingL),
                        child: Text(
                          'To start selling surplus items, please complete your store profile.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: _decoration(
                        'Shop Name',
                        'Your shop name',
                        Icons.storefront_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Shop name is required'
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    Text(
                      'Address',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      'Search and select your shop location (Malaysia).',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    PlacesAutocompleteField(
                      controller: _addressController,
                      hintText: 'Search shop address',
                      onPlaceSelected: (d) {
                        setState(() {
                          _shopLat = d.latitude;
                          _shopLng = d.longitude;
                          _shopPlaceId = d.placeId;
                        });
                      },
                      onChanged: (_) {
                        setState(() {
                          _shopLat = null;
                          _shopLng = null;
                          _shopPlaceId = null;
                        });
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration(
                        'Phone',
                        'e.g. 012-345 6789 or 011-1234 5678',
                        Icons.phone_outlined,
                      ).copyWith(
                        helperText: 'Malaysia (+60) mobile numbers only',
                      ),
                      validator: validateMalaysianMobileField,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _decoration(
                        'Description (optional)',
                        'Tell customers what you sell',
                        Icons.description_outlined,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    Text(
                      'Operating days',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildOperatingDaysChips(),
                    const SizedBox(height: AppConstants.paddingL),
                    Text(
                      'Operating hours',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildOperatingHoursPicker(),
                    _buildHoursHint(),
                    const SizedBox(height: AppConstants.paddingXL),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving || !_isComplete(existing)
                            ? null
                            : () => _save(merchantId, existing),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusM),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isOnboarding ? 'Continue' : 'Save',
                                style: AppTypography.buttonLarge,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

