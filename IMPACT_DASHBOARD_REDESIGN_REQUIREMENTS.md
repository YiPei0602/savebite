# Impact Dashboard Redesign Requirements

## Overview
Redesign of the personalized impact dashboard to match the clean, image-led layout style shown in the reference design (Image 2). The new design emphasizes visual clarity, bold metrics, and user engagement.

## Design Goals
- **Visual Impact**: Large, bold numbers that immediately communicate user impact
- **Simplicity**: Clean, uncluttered layout with clear hierarchy
- **Brand Consistency**: Use SaveBite's teal color palette (#00615F)
- **Mobile-First**: Optimized for mobile screens with responsive behavior

## Layout Structure

### 1. Header
- **Text**: "Your impact"
- **Style**: H2 typography, primary color (teal)
- **Alignment**: Left-aligned
- **Spacing**: 16px margin below

### 2. Metric Tiles Row (2 Cards)
Two equal-width cards displayed side-by-side:

#### Card 1: Money Saved
- **Icon**: Payment/money icon (outlined style)
- **Label**: "Money saved"
- **Value**: "RM 581" (example)
- **Background**: White surface with subtle border
- **Shadow**: Minimal elevation (2px blur)

#### Card 2: CO2e Saved
- **Icon**: Cloud icon (outlined style)
- **Label**: "CO2e saved"
- **Value**: "140 kg" (example)
- **Background**: White surface with subtle border
- **Shadow**: Minimal elevation (2px blur)

**Card Specifications**:
- Padding: 16px internal
- Border radius: 12px
- Border: 1px solid divider color
- Gap between cards: 16px
- Icon size: 32px
- Icon color: Primary teal
- Label: Body medium, primary color, medium weight
- Value: H2, primary color, bold weight

### 3. Hero Tile (Full-Width)
Large prominent card featuring surprise bags saved:

**Layout**:
- **Left Section (40%)**: Visual element
  - Gradient background (primaryDark to primary)
  - Shopping bag icon (72px)
  - Decorative circular patterns for depth
  
- **Right Section (60%)**: Content
  - Label: "Surprise Bags\nsaved"
  - Value: "53" (large, bold)
  - Padding: 24px

**Specifications**:
- Height: 160px
- Background: Primary teal gradient
- Border radius: 12px
- Shadow: Medium elevation with primary color tint
- Label: H5, white text, semi-bold
- Value: 48px font size, white text, bold

## Color Palette
- **Primary**: #00615F (Deep Teal)
- **Primary Dark**: #004643
- **Surface**: #FFFFFF (White)
- **Text on Primary**: #FFFFFF (White)
- **Divider**: #DEE2E6
- **Shadow**: rgba(0, 0, 0, 0.1)

## Typography
Using Inter font family:
- **Header**: 24px, bold
- **Metric Label**: 14px, medium weight
- **Metric Value**: 24px, bold
- **Hero Label**: 16px, semi-bold
- **Hero Value**: 48px, bold

## Spacing System
- **Container Padding**: 24px horizontal
- **Vertical Spacing**: 16px between sections
- **Card Internal Padding**: 16px
- **Hero Internal Padding**: 24px
- **Icon Spacing**: 8px below icon

## Data Model

### Metrics Displayed
1. **Money Saved** (Currency)
   - Calculation: Sum of (original_price - paid_price) for completed orders
   - Format: Currency symbol + amount (no decimals if >= 100)
   - Example: "RM 581"

2. **CO2e Saved** (Weight)
   - Calculation: surprise_bags_saved × co2e_per_bag_kg
   - Format: Number + " kg" (no decimals if >= 100)
   - Example: "140 kg"

3. **Surprise Bags Saved** (Count)
   - Calculation: Count of completed surprise bag orders
   - Format: Integer only
   - Example: "53"

### Data Source
- Endpoint: `GET /api/impact/summary`
- Response format:
```json
{
  "period": "lifetime",
  "money_saved": {
    "amount": 581.0,
    "currency": "MYR"
  },
  "co2e_saved_kg": 140.0,
  "surprise_bags_saved": 53,
  "as_of": "2025-12-05T11:10:00Z"
}
```

## States

### Loading State
- Display skeleton loaders:
  - Header skeleton (text line)
  - Two small card skeletons
  - One large hero skeleton
- Use shimmer effect for visual feedback

### Empty State (No Data)
- Show all tiles with zero values
- Optional message: "Start saving food to see your impact"
- Maintain layout structure

### Error State
- Non-blocking error banner
- Message: "We couldn't load your impact. Retry"
- Retry button to refresh data
- Maintain previous cached values if available

### Offline State
- Show last cached values
- Display "Offline" badge
- Hide retry button

## Interactions

### Tap Behavior (Optional v1)
- Tiles may be tappable to navigate to detailed impact page
- Visual feedback: Subtle scale animation on tap
- Haptic feedback on mobile

### Refresh
- Pull-to-refresh on profile screen refreshes impact data
- Manual refresh button (optional)

## Accessibility

### Semantic Structure
- Section with aria-label "Your impact"
- Each card as separate region with descriptive labels
- Proper heading hierarchy

### Screen Reader Support
- Icon descriptions
- Value announcements with units
- Label context

### Visual Accessibility
- WCAG AA contrast ratios:
  - Text on white: >= 4.5:1
  - Text on teal: >= 4.5:1 (white text passes)
- Focus indicators: 2px visible ring
- Touch targets: >= 48x48px

## Responsive Behavior

### Mobile (Default)
- Stacked layout as described
- Full-width tiles
- 24px side padding

### Tablet (>= 600px)
- Same layout maintained
- Max content width: 680px, centered
- Increased padding: 32px

### Desktop (>= 960px)
- Max content width: 960px, centered
- Maintain 2-column metric row
- Hero tile full-width within container

## Performance Requirements

### Loading Performance
- Skeleton appears < 100ms
- Data fetch p95 < 500ms
- Smooth animations at 60fps

### Caching Strategy
- Cache impact data for 5-15 minutes
- Revalidate on pull-to-refresh
- Store in local storage for offline access

## Analytics Events

### Tracking
- `impact_dashboard_viewed`: When section becomes visible
- `impact_metric_tapped`: {metric: "money" | "co2e" | "bags"}
- `impact_retry_clicked`: When retry button clicked
- `impact_error_shown`: When error state displayed

## Implementation Files

### Modified Files
1. `/lib/features/profile/screens/profile_screen.dart`
   - Updated `_buildImpactDashboard()` method
   - New `_buildMetricTile()` widget
   - New `_buildHeroTile()` widget

### Design System Files (No Changes Required)
- `/lib/core/theme/app_colors.dart` - Uses existing colors
- `/lib/core/theme/app_typography.dart` - Uses existing typography
- `/lib/core/constants/app_constants.dart` - Uses existing constants

### Assets
- `/assets/images/surprise_bag_placeholder.svg` - Optional bag image
- Currently using icon fallback (shopping_bag icon)

## Testing Checklist

### Visual Testing
- [ ] Layout matches reference design on mobile
- [ ] Proper spacing and alignment
- [ ] Colors match brand palette
- [ ] Typography hierarchy is clear
- [ ] Icons are properly sized and colored

### Functional Testing
- [ ] Metrics display correct values
- [ ] Number formatting is correct (currency, kg, count)
- [ ] Loading state shows skeletons
- [ ] Error state shows retry option
- [ ] Offline state shows cached data

### Responsive Testing
- [ ] Mobile (375px, 414px)
- [ ] Tablet (768px, 1024px)
- [ ] Desktop (1280px, 1920px)

### Accessibility Testing
- [ ] Screen reader announces all content
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] Contrast ratios pass WCAG AA

### Performance Testing
- [ ] Initial render < 100ms
- [ ] Animations smooth at 60fps
- [ ] No layout shifts during load

## Future Enhancements (v2)

### Advanced Features
- Time period filters (lifetime, last 30 days, last 12 months)
- Trend indicators (↑ 15% from last month)
- Detailed breakdown page with charts
- Social sharing capabilities
- Achievement badges and milestones
- Comparison with community average

### Visual Enhancements
- Actual product photography for bag image
- Animated counters on value changes
- Micro-interactions on hover/tap
- Confetti animation on milestones

### Data Enhancements
- Real-time updates via WebSocket
- Historical data visualization
- Export impact report (PDF)
- Personalized insights and tips

## Success Metrics

### User Engagement
- Increased time on profile screen
- Higher tap-through rate to detailed impact
- Improved user satisfaction scores

### Technical Metrics
- Page load time < 1s
- Error rate < 1%
- Cache hit rate > 80%

## Acceptance Criteria

✅ **Layout**
- Matches Image 2 pattern: two small tiles + one hero tile
- Proper spacing and alignment
- Responsive across all screen sizes

✅ **Content**
- Displays three key metrics: Money saved, CO2e saved, Surprise Bags saved
- Correct number formatting per locale
- Clear labels and hierarchy

✅ **States**
- Loading, empty, error, and offline states work correctly
- Smooth transitions between states

✅ **Accessibility**
- Keyboard navigable
- Screen reader friendly
- WCAG AA compliant

✅ **Performance**
- Fast initial render
- Smooth animations
- Efficient data caching

## Notes
- Current implementation uses icon fallback for bag image
- Real product image can be added later to `/assets/images/`
- Design is production-ready and matches brand guidelines
- All existing design tokens and constants are reused
