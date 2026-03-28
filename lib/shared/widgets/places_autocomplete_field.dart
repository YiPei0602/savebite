import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:savebite/app/theme/app_colors.dart';
import 'package:savebite/app/theme/app_typography.dart';
import 'package:savebite/core/constants/app_constants.dart';
import 'package:savebite/services/places_service.dart';

/// Text field + debounced autocomplete list; on selection loads Place Details.
///
/// Does not use Google Maps SDK — HTTP Places API only.
class PlacesAutocompleteField extends StatefulWidget {
  const PlacesAutocompleteField({
    super.key,
    this.placesService,
    this.controller,
    this.hintText = 'Search address',
    this.onPlaceSelected,
    this.onChanged,
  });

  final PlacesService? placesService;
  final TextEditingController? controller;
  final String hintText;

  /// Fires after Place Details succeeds (structured data).
  final void Function(PlaceDetailsResult details)? onPlaceSelected;

  /// User-typed text only (not fired for programmatic address updates after selection).
  final ValueChanged<String>? onChanged;

  @override
  State<PlacesAutocompleteField> createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  late final TextEditingController _controller;
  late final PlacesService _service;
  late final bool _ownsController;

  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<PlaceSuggestion> _suggestions = const [];
  bool _loadingSuggestions = false;
  bool _loadingDetails = false;
  String? _error;
  bool _isProgrammaticText = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _service = widget.placesService ?? PlacesService();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _suggestions = const [];
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    if (widget.placesService == null) {
      _service.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 380), () async {
      if (!mounted) return;
      final q = value.trim();
      if (q.length < 2) {
        setState(() {
          _suggestions = const [];
          _loadingSuggestions = false;
          _error = null;
        });
        return;
      }

      setState(() {
        _loadingSuggestions = true;
        _error = null;
      });

      try {
        final list = await _service.fetchSuggestions(q);
        if (!mounted) return;
        setState(() {
          _suggestions = list;
          _loadingSuggestions = false;
        });
      } on PlacesApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _loadingSuggestions = false;
          _error = e.message;
        });
      } catch (e, st) {
        debugPrint('PlacesAutocompleteField suggestions: $e\n$st');
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _loadingSuggestions = false;
          _error = 'Could not load suggestions';
        });
      }
    });
  }

  Future<void> _onSelect(PlaceSuggestion suggestion) async {
    setState(() {
      _suggestions = const [];
      _loadingDetails = true;
      _error = null;
    });
    _focusNode.unfocus();

    try {
      final details = await _service.getPlaceDetails(suggestion.placeId);
      if (!mounted) return;

      setState(() => _loadingDetails = false);

      _isProgrammaticText = true;
      _controller.text = details.formattedAddress;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _isProgrammaticText = false;

      if (kDebugMode) {
        debugPrint(
          '[Places] address: ${details.formattedAddress}\n'
          '[Places] lat: ${details.latitude}\n'
          '[Places] lng: ${details.longitude}\n'
          '[Places] placeId: ${details.placeId}',
        );
      }

      widget.onPlaceSelected?.call(details);
    } on PlacesApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDetails = false;
        _error = e.message;
      });
    } catch (e, st) {
      debugPrint('PlacesAutocompleteField details: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingDetails = false;
        _error = 'Could not load place details';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (value) {
            if (!_isProgrammaticText) {
              widget.onChanged?.call(value);
            }
            _onTextChanged(value);
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _loadingSuggestions || _loadingDetails
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: AppTypography.bodyMedium,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            _error!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        if (_focusNode.hasFocus && _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.paddingXS),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        s.description,
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _onSelect(s),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
