# ✅ Cart and Checkout Screens Requirements Checklist

## Step 4: Cart and Checkout Screens - COMPLETE

### Files Created
- ✅ **`lib/screens/cart_screen.dart`** - Complete cart implementation (600+ lines)
- ✅ **`lib/screens/checkout_screen.dart`** - Complete checkout implementation (700+ lines)

---

## 📋 CART SCREEN Requirements Verification

### 1. Header ✅

#### 'Your Cart' Title ✅
- ✅ **AppBar**: "Your Cart" in H3 typography
- ✅ **Clear Cart Button**: Trash icon in app bar
- ✅ **Confirmation Dialog**: Before clearing all items

**Code Location**: Line 191-223 in `cart_screen.dart`

```dart
AppBar(
  title: Text('Your Cart', style: AppTypography.h3),
  actions: [
    IconButton(
      icon: Icon(Icons.delete_outline),
      onPressed: () => showClearCartDialog(),
    ),
  ],
)
```

---

### 2. Cart Items List ✅

#### Row Item Design ✅
Each item displays in a horizontal row with:

**Thumbnail Image (Left)** ✅
- ✅ **Size**: 80x80 pixels
- ✅ **Rounded corners**: 8px
- ✅ **Network loading**: With error handling
- ✅ **Placeholder**: Food icon on error

**Code Location**: Line 312-332 in `cart_screen.dart`

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(AppConstants.radiusS),
  child: Image.network(
    item['imageUrl'],
    width: 80,
    height: 80,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        width: 80,
        height: 80,
        color: AppColors.surfaceVariant,
        child: Icon(Icons.fastfood),
      );
    },
  ),
)
```

**Item Name** ✅
- ✅ **Typography**: H5 (bold)
- ✅ **Examples**: "Surplus Pastry Box", "Mixed Bread Bundle"
- ✅ **Max lines**: 2 with ellipsis

**Code Location**: Line 342-348 in `cart_screen.dart`

```dart
Text(
  item['name'], // e.g., 'Surplus Pastry Box'
  style: AppTypography.h5,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

**Merchant Name** ✅
- ✅ **Display**: Below item name
- ✅ **Color**: Secondary text (grey)
- ✅ **Size**: Small body text

**Price Display** ✅
- ✅ **Discounted Price**: Orange (#FF9F1C), bold
- ✅ **Original Price**: Strikethrough, grey
- ✅ **Item Savings**: Green text showing savings per item

**Code Location**: Line 357-382 in `cart_screen.dart`

```dart
Row(
  children: [
    // Discounted price (orange, bold)
    Text(
      'RM${price.toStringAsFixed(2)}',
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.accent, // Orange #FF9F1C
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Original price (strikethrough, grey)
    Text(
      'RM${originalPrice.toStringAsFixed(2)}',
      style: AppTypography.bodySmall.copyWith(
        decoration: TextDecoration.lineThrough,
        color: AppColors.textSecondary,
      ),
    ),
  ],
)

// Item savings
Text(
  'Save RM${itemSavings.toStringAsFixed(2)}',
  style: AppTypography.bodySmall.copyWith(
    color: AppColors.success, // Green
    fontWeight: FontWeight.w600,
  ),
)
```

**Item Total Price** ✅
- ✅ **Position**: Top-right of row
- ✅ **Color**: Primary green
- ✅ **Calculation**: Price × Quantity
- ✅ **Typography**: H5 bold

**Code Location**: Line 395-402 in `cart_screen.dart`

```dart
Text(
  'RM${itemTotal.toStringAsFixed(2)}',
  style: AppTypography.h5.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  ),
)
```

---

### 3. Quantity Stepper (- 1 +) ✅

#### Stepper Design ✅
- ✅ **Layout**: Horizontal row with minus, number, plus
- ✅ **Border**: Grey border around entire stepper
- ✅ **Buttons**: Minus (-) and Plus (+) icons
- ✅ **Number Display**: Current quantity in center
- ✅ **Dividers**: Vertical lines between sections

**Code Location**: Line 408-465 in `cart_screen.dart`

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(AppConstants.radiusS),
  ),
  child: Row(
    children: [
      // Minus Button
      InkWell(
        onTap: () => _decrementQuantity(itemId),
        child: Container(
          padding: EdgeInsets.all(AppConstants.paddingS),
          child: Icon(Icons.remove, size: 18),
        ),
      ),
      
      // Quantity Display
      Container(
        padding: EdgeInsets.symmetric(horizontal: paddingM),
        decoration: BoxDecoration(
          border: Border.symmetric(
            vertical: BorderSide(color: AppColors.border),
          ),
        ),
        child: Text('$quantity', style: bold text),
      ),
      
      // Plus Button
      InkWell(
        onTap: () => _incrementQuantity(itemId),
        child: Container(
          padding: EdgeInsets.all(AppConstants.paddingS),
          child: Icon(Icons.add, size: 18),
        ),
      ),
    ],
  ),
)
```

#### Stepper Functionality ✅
- ✅ **Increment**: Adds 1 to quantity (up to max)
- ✅ **Decrement**: Removes 1 from quantity
- ✅ **Remove on Zero**: Shows confirmation dialog when quantity reaches 0
- ✅ **Max Validation**: Shows snackbar when max quantity reached
- ✅ **State Update**: Real-time cart total updates

**Code Location**: Line 91-136 in `cart_screen.dart`

```dart
void _incrementQuantity(String itemId) {
  setState(() {
    final item = _cartItems[itemId]!;
    final currentQuantity = item['quantity'] as int;
    final maxQuantity = item['maxQuantity'] as int;

    if (currentQuantity < maxQuantity) {
      item['quantity'] = currentQuantity + 1;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum quantity reached')),
      );
    }
  });
}

void _decrementQuantity(String itemId) {
  setState(() {
    final item = _cartItems[itemId]!;
    final currentQuantity = item['quantity'] as int;

    if (currentQuantity > 1) {
      item['quantity'] = currentQuantity - 1;
    } else {
      _showRemoveItemDialog(itemId); // Confirm removal
    }
  });
}
```

---

### 4. Footer Section ✅

#### Subtotal Row ✅
- ✅ **Label**: "Subtotal (X items)"
- ✅ **Value**: Total price of all items
- ✅ **Typography**: Body medium

**Code Location**: Line 477-492 in `cart_screen.dart`

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Subtotal ($_totalItems ${_totalItems == 1 ? 'item' : 'items'})',
      style: AppTypography.bodyMedium,
    ),
    Text(
      'RM${_subtotal.toStringAsFixed(2)}',
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
)
```

#### 'Total Savings' Row (Highlighted in Green) ✅
- ✅ **Background**: Green with opacity (#28A745)
- ✅ **Border**: Green border
- ✅ **Icon**: Savings icon
- ✅ **Label**: "Total Savings" in green
- ✅ **Value**: Savings amount in bold green
- ✅ **Calculation**: Original total - Discounted total

**Code Location**: Line 497-527 in `cart_screen.dart`

```dart
Container(
  padding: EdgeInsets.all(AppConstants.paddingM),
  decoration: BoxDecoration(
    color: AppColors.success.withOpacity(0.1), // Light green background
    borderRadius: BorderRadius.circular(AppConstants.radiusS),
    border: Border.all(
      color: AppColors.success.withOpacity(0.3), // Green border
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(Icons.savings_outlined, color: AppColors.success),
          SizedBox(width: AppConstants.paddingS),
          Text(
            'Total Savings',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.success, // Green text
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      Text(
        'RM${_totalSavings.toStringAsFixed(2)}',
        style: AppTypography.h5.copyWith(
          color: AppColors.success, // Bold green
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
)
```

#### 'Proceed to Checkout' Button (Full Width) ✅
- ✅ **Width**: Full width of screen
- ✅ **Color**: Primary Green (#00A86B)
- ✅ **Text**: "Proceed to Checkout" in white
- ✅ **Icon**: Arrow forward icon
- ✅ **Padding**: Large vertical padding
- ✅ **Action**: Navigates to checkout screen

**Code Location**: Line 532-555 in `cart_screen.dart`

```dart
SizedBox(
  width: double.infinity, // Full width
  child: ElevatedButton(
    onPressed: _proceedToCheckout,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, // Green #00A86B
      padding: EdgeInsets.symmetric(
        vertical: AppConstants.paddingL,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Proceed to Checkout', style: AppTypography.buttonLarge),
        SizedBox(width: AppConstants.paddingS),
        Icon(Icons.arrow_forward, size: 20),
      ],
    ),
  ),
)
```

---

### 5. Additional Features ✅

#### Empty Cart State ✅
- ✅ **Icon**: Large shopping cart icon
- ✅ **Message**: "Your Cart is Empty"
- ✅ **Description**: Helper text
- ✅ **Button**: "Browse Surplus Food" to go back

**Code Location**: Line 227-266 in `cart_screen.dart`

#### Remove Item Dialog ✅
- ✅ **Trigger**: When quantity decremented to 0
- ✅ **Confirmation**: "Remove Item?" dialog
- ✅ **Actions**: Cancel or Remove buttons

**Code Location**: Line 138-167 in `cart_screen.dart`

---

## 📋 CHECKOUT SCREEN Requirements Verification

### 1. Section 1: Fulfillment Toggle Switch ✅

#### Self-Pickup vs Delivery Toggle ✅
- ✅ **Design**: Two-option toggle switch
- ✅ **Default**: Self-Pickup selected
- ✅ **Layout**: Side-by-side buttons
- ✅ **Selected State**: Primary green background
- ✅ **Unselected State**: Grey background

**Code Location**: Line 169-280 in `checkout_screen.dart`

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(AppConstants.radiusM),
  ),
  child: Row(
    children: [
      // Self-Pickup Option
      Expanded(
        child: InkWell(
          onTap: () => setState(() => _isSelfPickup = true),
          child: Container(
            decoration: BoxDecoration(
              color: _isSelfPickup 
                  ? AppColors.primary  // Green when selected
                  : Colors.transparent,
            ),
            child: Column(
              children: [
                Icon(Icons.store, color: white/grey),
                Text('Self-Pickup'),
                Text('Free', style: green/white),
              ],
            ),
          ),
        ),
      ),
      
      // Delivery Option
      Expanded(
        child: InkWell(
          onTap: () => setState(() => _isSelfPickup = false),
          child: Container(
            decoration: BoxDecoration(
              color: !_isSelfPickup 
                  ? AppColors.primary 
                  : Colors.transparent,
            ),
            child: Column(
              children: [
                Icon(Icons.delivery_dining),
                Text('Delivery'),
                Text('RM5.00'),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
)
```

#### Self-Pickup Details ✅
- ✅ **Icons**: Store icon for pickup, delivery icon for delivery
- ✅ **Labels**: "Self-Pickup" (Free) and "Delivery" (RM5.00)
- ✅ **Visual feedback**: Color changes on selection

#### Static Map Placeholder (for Pickup Point) ✅
- ✅ **Display**: When Self-Pickup is selected
- ✅ **Height**: 150px
- ✅ **Design**: Gradient background with map icon
- ✅ **Location Pin**: Red pin in center
- ✅ **Border**: Rounded corners with border

**Code Location**: Line 286-332 in `checkout_screen.dart`

```dart
Container(
  height: 150,
  decoration: BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(AppConstants.radiusM),
    border: Border.all(color: AppColors.border),
  ),
  child: Stack(
    children: [
      // Map placeholder with gradient
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight.withOpacity(0.1),
              AppColors.primary.withOpacity(0.2),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.map,
            size: 60,
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
      ),
      
      // Location Pin
      Center(
        child: Icon(
          Icons.location_on,
          size: 40,
          color: AppColors.error, // Red pin
        ),
      ),
    ],
  ),
)
```

#### Pickup Location Information ✅
- ✅ **Merchant Name**: "The Baker's Cottage"
- ✅ **Address**: "123 Gurney Drive, Penang, 10250"
- ✅ **Pickup Time**: "Today, 6:00 PM - 8:00 PM"
- ✅ **Icons**: Store icon and clock icon

**Code Location**: Line 337-379 in `checkout_screen.dart`

#### Delivery Address (Alternative) ✅
- ✅ **Display**: When Delivery is selected
- ✅ **Address**: User's delivery address
- ✅ **Edit Button**: Icon button to edit address

**Code Location**: Line 381-417 in `checkout_screen.dart`

---

### 2. Section 2: Payment Method Selector ✅

#### Payment Options ✅
Three payment methods available:

**1. Credit/Debit Card** ✅
- ✅ **Icon**: Credit card icon
- ✅ **Title**: "Credit/Debit Card"
- ✅ **Subtitle**: "Visa, Mastercard, Amex"
- ✅ **Selection**: Radio button

**2. Stripe** ✅
- ✅ **Icon**: Payment icon
- ✅ **Title**: "Stripe"
- ✅ **Subtitle**: "Secure payment via Stripe"
- ✅ **Selection**: Radio button

**3. E-Wallet** ✅
- ✅ **Icon**: Wallet icon
- ✅ **Title**: "E-Wallet"
- ✅ **Subtitle**: "Touch 'n Go, GrabPay, Boost"
- ✅ **Selection**: Radio button

**Code Location**: Line 419-490 in `checkout_screen.dart`

#### Payment Option Design ✅
- ✅ **Selected State**: 
  - Green border (2px)
  - Light green background
  - Green icon and text
  - Filled radio button
- ✅ **Unselected State**:
  - Grey border (1px)
  - Grey background
  - Grey icon
  - Empty radio button

**Code Location**: Line 492-560 in `checkout_screen.dart`

```dart
Widget _buildPaymentOption(String value, String title, IconData icon, String subtitle) {
  final isSelected = _selectedPaymentMethod == value;

  return InkWell(
    onTap: () => setState(() => _selectedPaymentMethod = value),
    child: Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.primary.withOpacity(0.1)  // Light green
            : AppColors.surfaceVariant,
        border: Border.all(
          color: isSelected 
              ? AppColors.primary  // Green border
              : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon in colored container
          Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.surface,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          
          // Title and subtitle
          Column(
            children: [
              Text(title, style: green/black),
              Text(subtitle, style: grey),
            ],
          ),
          
          // Radio button
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}
```

---

### 3. Section 3: Order Summary/Total ✅

#### Summary Breakdown ✅
- ✅ **Subtotal**: Total of all items
- ✅ **Service Fee**: RM 2.00
- ✅ **Delivery Fee**: RM 5.00 (only if delivery selected)
- ✅ **Total Savings**: Green highlighted row
- ✅ **Divider**: Separates items from total
- ✅ **Total**: Large, bold, green text

**Code Location**: Line 562-663 in `checkout_screen.dart`

```dart
Column(
  children: [
    // Subtotal
    _buildSummaryRow(
      'Subtotal',
      'RM${widget.subtotal.toStringAsFixed(2)}',
    ),
    
    // Service Fee
    _buildSummaryRow(
      'Service Fee',
      'RM${_serviceFee.toStringAsFixed(2)}',
    ),
    
    // Delivery Fee (conditional)
    if (!_isSelfPickup)
      _buildSummaryRow(
        'Delivery Fee',
        'RM${_deliveryFee.toStringAsFixed(2)}',
      ),
    
    // Total Savings (Green highlighted)
    Container(
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        children: [
          Text(
            'Total Savings',
            style: green bold text,
          ),
          Text(
            '-RM${widget.totalSavings.toStringAsFixed(2)}',
            style: green bold text,
          ),
        ],
      ),
    ),
    
    Divider(),
    
    // Total
    Row(
      children: [
        Text('Total', style: AppTypography.h4),
        Text(
          'RM${_total.toStringAsFixed(2)}',
          style: AppTypography.h3.copyWith(
            color: AppColors.primary, // Green
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ],
)
```

#### Total Calculation ✅
- ✅ **Formula**: Subtotal + Service Fee + (Delivery Fee if applicable)
- ✅ **Dynamic**: Updates when fulfillment method changes
- ✅ **Display**: Large H3 typography in green

**Code Location**: Line 42-49 in `checkout_screen.dart`

```dart
double get _total {
  double total = widget.subtotal + _serviceFee;
  if (!_isSelfPickup) {
    total += _deliveryFee;
  }
  return total;
}
```

---

### 4. Bottom: 'Place Order' Button ✅

#### Button Design ✅
- ✅ **Width**: Full width
- ✅ **Color**: Primary Green (#00A86B)
- ✅ **Text**: "Place Order - RM XX.XX" in white
- ✅ **Icon**: Check circle icon
- ✅ **Padding**: Large vertical padding
- ✅ **Elevation**: 4px shadow
- ✅ **Fixed Position**: Stays at bottom

**Code Location**: Line 665-703 in `checkout_screen.dart`

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    boxShadow: [BoxShadow(...)],
  ),
  child: SafeArea(
    child: Padding(
      padding: EdgeInsets.all(AppConstants.paddingL),
      child: SizedBox(
        width: double.infinity, // Full width
        child: ElevatedButton(
          onPressed: _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // #00A86B Green
            padding: EdgeInsets.symmetric(
              vertical: AppConstants.paddingL,
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 24),
              SizedBox(width: AppConstants.paddingS),
              Text(
                'Place Order - RM${_total.toStringAsFixed(2)}',
                style: AppTypography.buttonLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
)
```

#### Place Order Functionality ✅
- ✅ **Loading State**: Shows circular progress indicator
- ✅ **Success Dialog**: Displays order confirmation
  - Success icon (green check)
  - "Order Placed!" message
  - Order number
  - "Back to Home" button
- ✅ **Navigation**: Returns to home screen after success

**Code Location**: Line 51-119 in `checkout_screen.dart`

```dart
void _placeOrder() {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );

  // Simulate processing
  Future.delayed(Duration(seconds: 2), () {
    Navigator.pop(context); // Close loading

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          children: [
            // Success icon
            Container(
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 60,
              ),
            ),
            
            Text('Order Placed!', style: green h3),
            Text('Order #SB12345'),
            
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  });
}
```

---

## 🎨 Design Compliance

### Colors Used ✅
- ✅ **Primary Green (#00A86B)**: Buttons, selected states, totals
- ✅ **Accent Orange (#FF9F1C)**: Discounted prices
- ✅ **Success Green (#28A745)**: Savings, confirmations
- ✅ **Error Red (#DC3545)**: Location pins
- ✅ **Background (#F8F9FA)**: Screen backgrounds
- ✅ **Surface White (#FFFFFF)**: Cards, sections

### Typography ✅
- ✅ **Poppins Font**: All text via `AppTypography`
- ✅ **H3**: Screen titles
- ✅ **H4**: Section headers
- ✅ **H5**: Item names, totals
- ✅ **Body Medium**: Labels, descriptions
- ✅ **Button Large**: Button text

---

## 🔗 Integration & Navigation

### Navigation Flow ✅
```
Merchant Details → View Cart → Cart Screen → Proceed to Checkout → Checkout Screen → Place Order → Success → Home
```

**Code Locations**:
1. Merchant Details → Cart: Line 746-770 in `merchant_details_screen.dart`
2. Cart → Checkout: Line 169-188 in `cart_screen.dart`
3. Checkout → Success → Home: Line 51-119 in `checkout_screen.dart`

---

## 🚀 How to Test

### Run the App
```bash
flutter run -d chrome
```

### Complete User Flow
1. **Login** → Home Screen
2. **Tap food card** → Merchant Details
3. **Add items** → Cart banner appears
4. **Tap "View Cart"** → Cart Screen opens
5. **Cart Screen**:
   - See 3 items with thumbnails, names, prices
   - Use quantity steppers (- 1 +)
   - See "Total Savings" in green
   - Tap "Proceed to Checkout"
6. **Checkout Screen**:
   - Toggle between Self-Pickup and Delivery
   - See map placeholder for pickup
   - Select payment method (Card/Stripe/E-Wallet)
   - Review order summary
   - Tap "Place Order"
7. **Success Dialog** → Order confirmed → Back to Home

### Interactive Features
- ✅ **Quantity Stepper**: +/- buttons work
- ✅ **Remove Item**: Decrement to 0 shows dialog
- ✅ **Clear Cart**: Trash icon clears all items
- ✅ **Fulfillment Toggle**: Switches between pickup/delivery
- ✅ **Payment Selection**: Radio buttons work
- ✅ **Total Updates**: Changes with delivery selection
- ✅ **Place Order**: Shows loading → success dialog

---

## ✅ Final Verification

### Cart Screen ✅

| Requirement | Status | Details |
|-------------|--------|---------|
| File created at `lib/screens/cart_screen.dart` | ✅ | 600+ lines |
| Header: 'Your Cart' | ✅ | H3 typography |
| List of items | ✅ | Vertical scrollable list |
| Thumbnail image | ✅ | 80x80px, left side |
| Item name | ✅ | H5 bold |
| Price display | ✅ | Orange discounted, grey original |
| Quantity stepper (- 1 +) | ✅ | Fully functional |
| Item total price | ✅ | Price × Quantity |
| Footer: Total Savings (Green) | ✅ | Highlighted container |
| 'Proceed to Checkout' button (Full width) | ✅ | Green, full width |
| Empty cart state | ✅ | Icon + message |
| Remove item dialog | ✅ | Confirmation required |
| Clear cart option | ✅ | App bar action |

### Checkout Screen ✅

| Requirement | Status | Details |
|-------------|--------|---------|
| File created at `lib/screens/checkout_screen.dart` | ✅ | 700+ lines |
| Section 1: Fulfillment toggle | ✅ | Self-Pickup vs Delivery |
| Default to Self-Pickup | ✅ | `_isSelfPickup = true` |
| Static map placeholder | ✅ | 150px with gradient + pin |
| Pickup location info | ✅ | Address + time |
| Delivery address (alternative) | ✅ | Shows when delivery selected |
| Section 2: Payment selector | ✅ | 3 options |
| Card payment option | ✅ | With icon + subtitle |
| Stripe payment option | ✅ | With icon + subtitle |
| E-Wallet payment option | ✅ | With icon + subtitle |
| Radio button selection | ✅ | Visual feedback |
| Section 3: Order summary | ✅ | Complete breakdown |
| Subtotal row | ✅ | All items total |
| Service fee row | ✅ | RM 2.00 |
| Delivery fee row (conditional) | ✅ | RM 5.00 if delivery |
| Total savings (green) | ✅ | Highlighted row |
| Total row | ✅ | Large, bold, green |
| Bottom: 'Place Order' button | ✅ | Full width, #00A86B |
| Button shows total | ✅ | "Place Order - RM XX.XX" |
| Loading state | ✅ | Progress indicator |
| Success dialog | ✅ | Order confirmation |
| Navigation to home | ✅ | After success |

---

## 🎉 Summary

**ALL REQUIREMENTS MET! ✅**

Both Cart and Checkout screens have been successfully implemented with:

### Cart Screen ✅
- Complete item list with thumbnails, names, prices
- Functional quantity steppers (- 1 +)
- Total savings highlighted in green
- Full-width "Proceed to Checkout" button
- Empty cart state
- Item removal with confirmation

### Checkout Screen ✅
- Fulfillment toggle (Self-Pickup vs Delivery)
- Static map placeholder for pickup point
- Payment method selector (Card/Stripe/E-Wallet)
- Complete order summary with dynamic total
- Large "Place Order" button in #00A86B
- Success flow with order confirmation

**Ready to test the complete checkout flow!** 🚀🛒
