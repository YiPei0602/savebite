import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/core/theme/app_colors.dart';
import 'package:savebite/core/theme/app_typography.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/food_item_model.dart';
import 'package:savebite/features/marketplace_surplus/domain/models/merchant_model.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/food_provider.dart';
import 'package:savebite/shared/utils/merchant_schedule_utils.dart';
import 'package:savebite/features/marketplace_surplus/state/providers/merchant_provider.dart';
import 'package:savebite/features/merchant_management/presentation/widgets/food_hygiene_policy_sheet.dart';
import 'package:savebite/shared/widgets/app_back_button.dart';

/// Copy for merchant-only food safety gate (new listings only; not persisted).
class _FoodSafetyDeclarationCopy {
  _FoodSafetyDeclarationCopy._();

  static const title = 'Food Safety Confirmation';

  static const intro =
      'Before publishing this listing, confirm that:\n'
      '\n'
      '• The food is clean, safe, and suitable for consumption.\n'
      '• The item has not expired.\n'
      '• The information you provide is accurate.\n'
      '• The food was handled hygienically.';

  /// Single gate for new listings (not persisted).
  static const checkboxPolicyCompliance =
      'I confirm that this listing complies with the SaveBite '
      'Food Hygiene & Safety Policy.';
}

/// Add Surplus Item Screen
///
/// UI-only form placeholder. Publishing surplus requires backend integration.
class AddSurplusScreen extends StatefulWidget {
  final FoodItemModel? initialItem;

  const AddSurplusScreen({super.key, this.initialItem});

  @override
  State<AddSurplusScreen> createState() => _AddSurplusScreenState();
}

class _AddSurplusScreenState extends State<AddSurplusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imageContentType;
  String? _existingImageUrl;
  MerchantModel? _merchantSnapshot;

  final Set<_ListingTag> _selectedTags = <_ListingTag>{};
  double _minDiscount = 20.0;
  double _maxDiscount = 70.0;
  bool _isLoading = false;

  /// Required once per **new** listing; not persisted.
  bool _confirmHygienePolicy = false;

  /// Always derived from store profile (same instant as store closing for this session).
  DateTime get _effectiveClosingTime {
    final fromStore = _closingTimeFromStore(_merchantSnapshot);
    if (fromStore != null) return fromStore;
    return widget.initialItem?.closingTime ??
        DateTime.now().add(const Duration(hours: 6));
  }

  /// Derives item closing time from store's operating schedule (Store Profile).
  /// Uses the **next closing instant** for the current session (including overnight
  /// e.g. Tue 11:00 → Wed 01:00).
  DateTime? _closingTimeFromStore(MerchantModel? m) {
    if (m == null) return null;
    return closingInstantForCurrentOpenSessionMalaysia(m);
  }

  static const List<_ListingTag> _tagOptions = <_ListingTag>[
    _ListingTag.foodCategory(FoodCategory.mysteryBag, 'Mystery'),
    _ListingTag.foodCategory(FoodCategory.preparedMeals, 'Meals'),
    _ListingTag.foodCategory(FoodCategory.bakery, 'Bakeries'),
    _ListingTag.foodCategory(FoodCategory.beverages, 'Drinks'),
    _ListingTag.foodCategory(FoodCategory.groceries, 'Groceries'),
    _ListingTag.dietary(DietaryTag.vegetarian, 'Veggie'),
    _ListingTag.dietary(DietaryTag.halal, 'Halal'),
  ];

  @override
  void initState() {
    super.initState();

    final item = widget.initialItem;
    if (item == null) return;

    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _originalPriceController.text = item.originalPrice.toStringAsFixed(2);
    _quantityController.text = item.stock.toString();
    _existingImageUrl = item.imageUrl;

    final range = item.discountRange;
    if (range != null) {
      _minDiscount = range.minPercent.toDouble();
      _maxDiscount = range.maxPercent.toDouble();
    } else {
      _minDiscount = item.discountPercentage.toDouble();
      _maxDiscount = item.discountPercentage.toDouble();
    }

    for (final opt in _tagOptions) {
      final foodCat = opt.foodCategory;
      final dietary = opt.dietaryTag;
      if (foodCat != null && item.effectiveCategories.contains(foodCat)) {
        _selectedTags.add(opt);
      }
      if (dietary != null && item.dietaryTags.contains(dietary)) {
        _selectedTags.add(opt);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  int get _computedDiscountPercent {
    final max = _maxDiscount.round().clamp(0, 100);
    final min = _minDiscount.round().clamp(0, max);
    final span = max - min;
    if (span == 0) return min;

    final minutesLeft = _effectiveClosingTime.difference(DateTime.now()).inMinutes;
    if (minutesLeft <= 0) return max;

    final double t;
    if (minutesLeft > 240) {
      t = 0.0;
    } else if (minutesLeft > 120) {
      t = 0.2;
    } else if (minutesLeft > 60) {
      t = 0.4;
    } else if (minutesLeft > 30) {
      t = 0.7;
    } else {
      t = 1.0;
    }
    return (min + (span * t)).round().clamp(0, 100);
  }

  double get _discountedPrice {
    final original = double.tryParse(_originalPriceController.text) ?? 0;
    return original * (1 - _computedDiscountPercent / 100);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initialItem != null;

    // UX guard: store profile must be complete before any backend call.
    final merchant = _merchantSnapshot;
    final storeComplete = merchant != null &&
        merchant.name.trim().isNotEmpty &&
        merchant.address.trim().isNotEmpty &&
        merchant.phoneNumber.trim().isNotEmpty;
    if (!storeComplete) {
      // Button is disabled in UI, but keep a safety guard.
      return;
    }

    if (!isEdit && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item photo')),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 category')),
      );
      return;
    }

    if (!isEdit) {
      if (!_confirmHygienePolicy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please confirm the Food Hygiene & Safety policy before publishing.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final foodProvider = context.read<FoodProvider>();
      final user = authProvider.currentUser;

      final merchantId = user?.merchantId ?? user?.id;
      if (merchantId == null || merchantId.isEmpty || user == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in again to continue.')),
        );
        return;
      }

      final merchantName = merchant.name.trim();

      final originalPrice = double.parse(_originalPriceController.text);
      final stock = int.parse(_quantityController.text);
      final minInt = _minDiscount.round().clamp(0, 100);
      final maxInt = _maxDiscount.round().clamp(0, 100);
      final discountRange = DiscountRange(
        minPercent: minInt <= maxInt ? minInt : maxInt,
        maxPercent: maxInt,
      );
      final discountInt = _computedDiscountPercent;
      final discountedPrice = originalPrice * (1 - discountInt / 100);

      final selectedFoodCategories = _selectedTags
          .where((t) => t.foodCategory != null)
          .map((t) => t.foodCategory!)
          .toList(growable: false);
      final primaryCategory = selectedFoodCategories.isNotEmpty
          ? selectedFoodCategories.first
          : FoodCategory.other;

      final selectedDietary = _selectedTags
          .where((t) => t.dietaryTag != null)
          .map((t) => t.dietaryTag!)
          .toSet()
          .toList(growable: false);
      final dietaryTags =
          selectedDietary.isEmpty ? const [DietaryTag.none] : selectedDietary;

      final item = FoodItemModel(
        id: isEdit
            ? widget.initialItem!.id
            : 'draft-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        merchantId: merchantId,
        merchantName: merchantName,
        description: _descriptionController.text.trim(),
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        discountPercentage: discountInt,
        discountRange: discountRange,
        stock: stock,
        category: primaryCategory,
        categories: selectedFoodCategories,
        dietaryTags: dietaryTags,
        closingTime: _effectiveClosingTime,
        imageUrl: isEdit ? (_existingImageUrl ?? '') : '',
        listingStatus:
            isEdit ? widget.initialItem!.listingStatus : ListingStatus.active,
        createdAt: isEdit ? widget.initialItem!.createdAt : DateTime.now(),
        updatedAt: isEdit ? DateTime.now() : null,
      );

      final ok = isEdit
          ? await foodProvider.updateFoodItem(
              item,
              imageBytes: _imageBytes,
              imageFileName: _imageFileName,
              imageContentType: _imageContentType,
            )
          : await foodProvider.createFoodItem(
              item,
              imageBytes: _imageBytes,
              imageFileName: _imageFileName,
              imageContentType: _imageContentType,
            );
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to publish item. Please try again.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Listing updated' : 'Listing published')),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/merchant-dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('[AddSurplusScreen] publish failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to publish item. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final merchantId = auth.currentUser?.merchantId ?? auth.currentUser?.id;
    final merchantProvider = context.read<MerchantProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          widget.initialItem == null ? 'Add Surplus Item' : 'Edit Listing',
          style: AppTypography.h4,
        ),
        centerTitle: true,
      ),
      body: (merchantId == null || merchantId.isEmpty)
          ? Center(
              child: Text(
                'Merchant session missing. Please log in again.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          : StreamBuilder<MerchantModel?>(
              stream: merchantProvider.watchMerchant(merchantId),
              builder: (context, snapshot) {
                _merchantSnapshot = snapshot.data;
                final merchant = snapshot.data;
                final storeComplete = merchant != null &&
                    merchant.name.trim().isNotEmpty &&
                    merchant.address.trim().isNotEmpty &&
                    merchant.phoneNumber.trim().isNotEmpty;

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    children: [
                      _buildImageUploadSection(),
                      const SizedBox(height: 24),
                      _buildFloatingField(
                        controller: _nameController,
                        label: 'Item Name',
                        hint: 'e.g., Surplus Pastry Box',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFloatingField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Describe what\'s included...',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildCategorySection(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFloatingField(
                              controller: _originalPriceController,
                              label: 'Original Price (RM)',
                              hint: '0.00',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (double.tryParse(value) == null) return 'Invalid';
                                return null;
                              },
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFloatingField(
                              controller: _quantityController,
                              label: 'Quantity',
                              hint: '0',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (int.tryParse(value) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDiscountSection(),
                      const SizedBox(height: 24),
                      _buildPriceSummaryCard(),
                      const SizedBox(height: 20),

                      if (!storeComplete) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete your store profile to start selling',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => context.goNamed('merchant-profile'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.radiusM,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Go to Profile'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (widget.initialItem == null) ...[
                        _buildFoodSafetyDeclarationSection(),
                        const SizedBox(height: 20),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_isLoading ||
                                  !storeComplete ||
                                  (widget.initialItem == null &&
                                      !_confirmHygienePolicy))
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.initialItem == null
                                      ? 'Add Item'
                                      : 'Save Changes',
                                  style: AppTypography.buttonLarge,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFoodSafetyDeclarationSection() {
    // Same size & weight for intro + checkbox line; title uses [cardTitleStyle]. Link unchanged.
    final cardBodyStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
      height: 1.45,
      fontWeight: FontWeight.w400,
    );
    final cardTitleStyle = AppTypography.bodyMedium.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _FoodSafetyDeclarationCopy.title,
            style: cardTitleStyle,
          ),
          const SizedBox(height: 10),
          Text(
            _FoodSafetyDeclarationCopy.intro,
            style: cardBodyStyle,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _confirmHygienePolicy,
            onChanged: _isLoading
                ? null
                : (v) =>
                    setState(() => _confirmHygienePolicy = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              _FoodSafetyDeclarationCopy.checkboxPolicyCompliance,
              style: cardBodyStyle,
            ),
            activeColor: AppColors.primary,
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed:
                  _isLoading ? null : () => showFoodHygienePolicySheet(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
              child: Text(
                'View full policy',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    final existingUrl = _existingImageUrl;
    final hasExistingImage =
        _imageBytes == null && existingUrl != null && existingUrl.isNotEmpty;

    return InkWell(
      onTap: _isLoading ? null : _pickImage,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: AppColors.textTertiary.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: (_imageBytes == null && !hasExistingImage)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add Item Photo',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select photo',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    child: hasExistingImage
                        ? (existingUrl.startsWith('assets/')
                            ? Image.asset(existingUrl, fit: BoxFit.cover)
                            : Image.network(
                                existingUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(
                                      Icons.fastfood,
                                      color: AppColors.textTertiary,
                                      size: 40,
                                    ),
                                  );
                                },
                              ))
                        : Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Material(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _isLoading
                            ? null
                            : () => setState(() {
                                  _imageBytes = null;
                                  _imageFileName = null;
                                  _imageContentType = null;
                                }),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.close, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        // Reduce upload size for reliability.
        imageQuality: 70,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      final fileName = picked.name;
      final ext = fileName.toLowerCase();
      final contentType = ext.endsWith('.png')
          ? 'image/png'
          : ext.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      setState(() {
        _imageBytes = bytes;
        _imageFileName = fileName;
        _imageContentType = contentType;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick image')),
      );
    }
  }

  Widget _buildFloatingField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AppTypography.inputHint.copyWith(
          color: const Color(0xFF60646C),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _tagOptions.map((tag) {
            final selected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag.label),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Discount',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_minDiscount.round()}% – ${_maxDiscount.round()}%  (now $_computedDiscountPercent%)',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: RangeValues(_minDiscount, _maxDiscount),
          min: 10,
          max: 90,
          divisions: 16,
          labels: RangeLabels(
            '${_minDiscount.round()}%',
            '${_maxDiscount.round()}%',
          ),
          onChanged: (values) {
            setState(() {
              _minDiscount = values.start;
              _maxDiscount = values.end;
            });
          },
          activeColor: AppColors.accent,
          inactiveColor: AppColors.accent.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildPriceSummaryCard() {
    final originalPrice = double.tryParse(_originalPriceController.text) ?? 0;
    final savings = originalPrice - _discountedPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Original Price',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                'RM ${originalPrice.toStringAsFixed(2)}',
                style: AppTypography.h5.copyWith(
                  color: Colors.white,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discounted Price',
                style: AppTypography.h5.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RM ${_discountedPrice.toStringAsFixed(2)}',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Customers save RM ${savings.toStringAsFixed(2)}',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingTag {
  final FoodCategory? foodCategory;
  final DietaryTag? dietaryTag;
  final String label;

  const _ListingTag._({
    required this.label,
    this.foodCategory,
    this.dietaryTag,
  });

  const _ListingTag.foodCategory(FoodCategory category, String label)
      : this._(label: label, foodCategory: category);

  const _ListingTag.dietary(DietaryTag tag, String label)
      : this._(label: label, dietaryTag: tag);
}

