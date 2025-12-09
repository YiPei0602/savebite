# Consumer Discovery Testing Guide

## Quick Test Commands

### 1. Run Unit Tests
```bash
flutter test test/price_utils_test.dart
```
**Expected:** All 12 tests pass ✅

### 2. Run the App
```bash
flutter run -d E298B83E-5A30-45CD-995D-8EF53E7FCF63
```
**Expected:** App launches on iOS Simulator

### 3. Check for Errors
```bash
flutter analyze
```
**Expected:** No errors (only warnings if any)

---

## Manual Testing Checklist

### Test 1: Initial Load
**Steps:**
1. Launch app
2. Login (any email/password)
3. Select Consumer role
4. Navigate to Home tab

**Expected:**
- ✅ Loading indicator appears briefly
- ✅ 6 food items load from FoodProvider
- ✅ Items display with images, names, prices
- ✅ Dynamic prices show (different from static mock)
- ✅ Discount badges show current percentage

### Test 2: Search Functionality
**Steps:**
1. Click search bar
2. Type "Pastry"
3. Wait 300ms

**Expected:**
- ✅ Search debounces (doesn't search immediately)
- ✅ After 300ms, list filters to show "Surplus Pastry Box"
- ✅ Clear button (X) appears in search bar
- ✅ Clicking X clears search and shows all items

### Test 3: Category Filters (Multi-select)
**Steps:**
1. Click "Bakery" category tile
2. Click "Meals" category tile
3. Click "Bakery" again to deselect

**Expected:**
- ✅ Bakery tile highlights when selected
- ✅ List shows only bakery items
- ✅ Clicking Meals adds to filter (shows bakery + meals)
- ✅ Clicking Bakery again removes it (shows only meals)
- ✅ Multiple categories can be selected simultaneously

### Test 4: Dietary Filters
**Steps:**
1. Click "Halal" chip
2. Click "Vegetarian" chip
3. Click "Halal" again to deselect

**Expected:**
- ✅ Halal chip turns orange when selected
- ✅ List shows items with Halal tag
- ✅ Adding Vegetarian shows items with either tag
- ✅ Deselecting Halal shows only Vegetarian items
- ✅ Multiple dietary tags can be selected

### Test 5: Location Filter
**Steps:**
1. Click location dropdown in header
2. Select "Kuala Lumpur"
3. Select "Penang" again

**Expected:**
- ✅ Modal bottom sheet opens
- ✅ Current location shows checkmark
- ✅ Selecting new location updates header
- ✅ List filters by location (mock: shows all for now)
- ✅ Modal closes after selection

### Test 6: Combined Filters
**Steps:**
1. Type "Bag" in search
2. Select "Bakery" category
3. Select "Vegetarian" dietary tag

**Expected:**
- ✅ All filters apply together
- ✅ Shows only items matching ALL criteria
- ✅ Item count updates in header
- ✅ Empty state shows if no matches

### Test 7: Dynamic Pricing
**Steps:**
1. Observe prices on food cards
2. Note the discount percentages
3. Wait a few minutes and refresh

**Expected:**
- ✅ Prices show with dynamic discount calculation
- ✅ Original price struck through
- ✅ Discounted price in orange/bold
- ✅ Discount badge shows current percentage
- ✅ Discount increases as closing time approaches

### Test 8: Closing Soon Badge
**Steps:**
1. Look for items with "Closing Soon" badge
2. Check the countdown timer

**Expected:**
- ✅ Badge appears for items <30 minutes to closing
- ✅ Shows time remaining (e.g., "25m")
- ✅ Red color for urgency
- ✅ Timer updates (if you wait)

### Test 9: Empty State
**Steps:**
1. Search for "xyz123" (non-existent)
2. Click "Clear Filters" button

**Expected:**
- ✅ Empty state shows with icon and message
- ✅ "No items found" message displays
- ✅ "Clear Filters" button appears
- ✅ Clicking button resets all filters
- ✅ All items reappear

### Test 10: Error State
**Steps:**
1. Temporarily break FoodService (throw error)
2. Restart app

**Expected:**
- ✅ Error icon and message display
- ✅ "Retry" button appears
- ✅ Clicking retry attempts to reload
- ✅ App doesn't crash

### Test 11: Navigation
**Steps:**
1. Click on any food item card
2. Verify merchant details screen opens

**Expected:**
- ✅ Navigates to merchant details
- ✅ Shows correct merchant info
- ✅ Back button returns to home
- ✅ No data loss

### Test 12: Performance
**Steps:**
1. Type quickly in search bar
2. Toggle multiple filters rapidly
3. Scroll through list

**Expected:**
- ✅ Search debounces (doesn't lag)
- ✅ Filters apply smoothly
- ✅ No stuttering or freezing
- ✅ Smooth scrolling

---

## Console Output to Verify

When app launches, you should see:
```
Food items loaded: 6
Merchants loaded: 4
Cart empty: true
```

When searching, you should see:
```
Filtering items with query: pastry
Filtered items: 1
```

When toggling filters, you should see:
```
Category filter updated: bakery
Dietary filter updated: halal
Location filter updated: Penang
```

---

## Known Issues & Limitations

### Current Limitations
1. **Location filter is mock** - Shows all items regardless of location
   - TODO: Integrate with merchant location data
   
2. **Distance calculation is mock** - Shows static 2.3 km
   - TODO: Calculate real distance using geolocation

3. **No real-time updates** - Prices don't update automatically
   - TODO: Add Firestore listeners for real-time changes

4. **No image upload** - Uses placeholder images
   - TODO: Integrate Firebase Storage

### Expected Behavior
- All filters work together (AND logic)
- Search is case-insensitive
- Multi-select allows multiple categories/dietary tags
- Dynamic pricing updates based on closing time
- Closing soon badge appears <30 minutes

---

## Debugging Tips

### Issue: Items not loading
**Check:**
```dart
// In home_screen.dart initState
print('Food items: ${context.read<FoodProvider>().allFoodItems.length}');
```
**Expected:** Should print "6"

### Issue: Search not working
**Check:**
```dart
// In _onSearchChanged
print('Search query: $query');
```
**Expected:** Should print after 300ms delay

### Issue: Filters not applying
**Check:**
```dart
// In FoodProvider._applyFilters
print('Filtered items: ${_filteredFoodItems.length}');
```
**Expected:** Should print filtered count

### Issue: Dynamic pricing not showing
**Check:**
```dart
// In _buildSurplusCard
print('Dynamic discount: $currentDiscount%');
print('Dynamic price: RM$dynamicPrice');
```
**Expected:** Should print calculated values

---

## Performance Benchmarks

### Expected Performance
- **Initial load:** <2 seconds
- **Search debounce:** 300ms
- **Filter application:** <100ms
- **Scroll performance:** 60 FPS
- **Memory usage:** <150 MB

### If Performance Issues
1. Check if too many rebuilds (use `debugPrint` in build)
2. Verify debounce is working (search shouldn't trigger immediately)
3. Check if images are loading efficiently
4. Monitor console for errors

---

## Success Criteria

### ✅ All Tests Pass
- [x] Unit tests pass (12/12)
- [x] App compiles without errors
- [x] No diagnostics errors

### ✅ Features Work
- [x] Search with debounce
- [x] Multi-select category filters
- [x] Multi-select dietary filters
- [x] Location dropdown
- [x] Dynamic pricing display
- [x] Closing soon badges
- [x] Countdown timers
- [x] Loading states
- [x] Empty states
- [x] Error states

### ✅ No Breaking Changes
- [x] Navigation still works
- [x] Cart still works
- [x] Checkout still works
- [x] All other screens unaffected

---

## Next Steps After Testing

1. **If all tests pass:**
   - Update marketplace screen similarly
   - Integrate cart with CartProvider
   - Update checkout with OrderProvider

2. **If issues found:**
   - Check console logs
   - Verify provider initialization
   - Test individual components
   - Review error messages

3. **Future enhancements:**
   - Add sort options (price, distance, discount)
   - Add favorites/saved items
   - Add map view
   - Implement real-time updates

---

## Quick Commands Reference

```bash
# Run tests
flutter test test/price_utils_test.dart

# Run app on iOS
flutter run -d E298B83E-5A30-45CD-995D-8EF53E7FCF63

# Run app on Chrome (faster for testing)
flutter run -d chrome

# Hot reload (while app is running)
# Press 'r' in terminal

# Hot restart (while app is running)
# Press 'R' in terminal

# Check for errors
flutter analyze

# Clean build (if issues)
flutter clean && flutter pub get
```

---

## Support

If you encounter issues:
1. Check `CONSUMER_DISCOVERY_UPGRADE_SUMMARY.md` for implementation details
2. Review `ARCHITECTURE_UPGRADE_GUIDE.md` for provider usage
3. Check console logs for error messages
4. Verify provider initialization in main.dart

---

**Status: Ready for Testing** ✅
**All Features Implemented** ✅
**Tests Passing** ✅
