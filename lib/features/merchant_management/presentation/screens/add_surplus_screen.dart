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
import 'package:savebite/features/marketplace_surplus/state/providers/food_provider.dart';

/// Add Surplus Item Screen
///
/// UI-only form placeholder. Publishing surplus requires backend integration.
class AddSurplusScreen extends StatefulWidget {
  const AddSurplusScreen({super.key});

  @override
  State<AddSurplusScreen> createState() => _AddSurplusScreenState();
}

class _AddSurplusScreenState extends State<AddSurplusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imageContentType;

  final Set<_ListingTag> _selectedTags = <_ListingTag>{};
  double _discountPercentage = 50.0;
  bool _isLoading = false;

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
  void dispose() {
    _shopNameController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  double get _discountedPrice {
    final original = double.tryParse(_originalPriceController.text) ?? 0;
    return original * (1 - _discountPercentage / 100);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
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

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final foodProvider = context.read<FoodProvider>();
      final user = authProvider.currentUser;

      final merchantId = user?.merchantId ?? user?.id;
      if (merchantId == null || merchantId.isEmpty || user == null) {
        throw Exception('Merchant session missing. Please log in again.');
      }
      final merchantName = _shopNameController.text.trim().isNotEmpty
          ? _shopNameController.text.trim()
          : (user.name.isNotEmpty ? user.name : 'Your Store');

      final originalPrice = double.parse(_originalPriceController.text);
      final stock = int.parse(_quantityController.text);
      final discountInt = _discountPercentage.round().clamp(0, 100);
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
        id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        merchantId: merchantId,
        merchantName: merchantName,
        description: _descriptionController.text.trim(),
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        discountPercentage: discountInt,
        stock: stock,
        category: primaryCategory,
        categories: selectedFoodCategories,
        dietaryTags: dietaryTags,
        closingTime: DateTime.now().add(const Duration(hours: 6)),
        imageUrl: '',
        createdAt: DateTime.now(),
      );

      final ok = await foodProvider.createFoodItem(
        item,
        imageBytes: _imageBytes,
        imageFileName: _imageFileName,
        imageContentType: _imageContentType,
      );
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(foodProvider.errorMessage ?? 'Unable to publish item'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing published')),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/merchant-dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().isEmpty
                ? 'Unable to publish item. Please try again.'
                : e.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/merchant-dashboard');
            }
          },
        ),
        title: Text('Add Surplus Item', style: AppTypography.h4),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          children: [
            _buildImageUploadSection(),
            const SizedBox(height: 24),
            _buildFloatingField(
              controller: _shopNameController,
              label: 'Shop Name',
              hint: 'e.g., Marcus Bakery',
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFloatingField(
              controller: _nameController,
              label: 'Item Name',
              hint: 'e.g., Surplus Pastry Box',
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter item name';
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
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
                    : Text('Add Item', style: AppTypography.buttonLarge),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
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
        child: _imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
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
                    child: Image.memory(
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
                '${_discountPercentage.round()}% OFF',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.accent.withOpacity(0.2),
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: _discountPercentage,
            min: 10,
            max: 90,
            divisions: 16,
            label: '${_discountPercentage.round()}%',
            onChanged: (value) => setState(() => _discountPercentage = value),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '10%',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '90%',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
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

