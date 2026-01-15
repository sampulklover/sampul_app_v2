> **📘 Master Guide**: For complete pricing/subscription documentation including admin guide for managing plans, see [PRICING_SUBSCRIPTION_GUIDE.md](./PRICING_SUBSCRIPTION_GUIDE.md)

# Subscription Feature Gating Guide

This guide shows how to control user access to features based on their subscription plan.

## Quick Start

Import the subscription checker:

```dart
import 'package:your_app/services/subscription_checker.dart';
```

## How It Works

The `SubscriptionChecker` is **plan-agnostic** and works with any number of plans:

1. **Automatically fetches plans from Stripe** - No hardcoded plan names
2. **Uses price amount to determine tier** - Free (price = 0) vs Paid (price > 0)
3. **Supports checking specific plans** - By price ID or plan name
4. **Scales automatically** - Add new plans in Stripe, no code changes needed

## Basic Usage Examples

### 1. Check if user has active subscription

```dart
final hasSubscription = await SubscriptionChecker.instance.hasActiveSubscription();
if (hasSubscription) {
  // User has active subscription
} else {
  // Show upgrade prompt
}
```

### 2. Check plan tier (Free vs Paid)

```dart
final tier = await SubscriptionChecker.instance.getPlanTier();
// Returns: 'free', 'paid', or null (no subscription)

if (tier == 'paid') {
  // Show all features
} else if (tier == 'free') {
  // Show limited features
} else {
  // No subscription - show upgrade prompt
}
```

### 3. Check specific plan (by price ID or name)

```dart
// Check by price ID
final isOnSecure = await SubscriptionChecker.instance.isOnPlan('price_1SettpE99PYceOfPV2CUQeh3');

// Check by plan name (case-insensitive)
final isOnSecureByName = await SubscriptionChecker.instance.isOnPlanByName('Secure Plan Sandbox');
```

### 4. Get current plan details

```dart
final currentPlan = await SubscriptionChecker.instance.getCurrentPlan();
if (currentPlan != null) {
  print('Plan: ${currentPlan.name}');
  print('Price: ${currentPlan.amount} ${currentPlan.currency}');
  print('Interval: ${currentPlan.interval}');
}
```

### 3. Gate asset creation (Free: max 5, Secure: unlimited)

```dart
// In your add asset screen
Future<void> _addAsset() async {
  final currentCount = await _getCurrentAssetCount();
  final canAdd = await SubscriptionChecker.instance.canAddAsset(
    currentAssetCount: currentCount,
  );

  if (!canAdd) {
    _showUpgradeDialog(
      message: 'Free plan allows up to 5 assets. Upgrade to Secure plan for unlimited assets.',
    );
    return;
  }

  // Proceed with adding asset
}
```

### 4. Check specific feature access

```dart
// Check if user can use Nazar/Fidyah clause
final canUseNazar = await SubscriptionChecker.instance.hasFeature('nazar_fidyah_clause');
if (!canUseNazar) {
  // Show upgrade prompt or disable feature
  return;
}

// Check if user can appoint guardian
final canAppointGuardian = await SubscriptionChecker.instance.hasFeature('appointment_of_guardian');
```

### 5. Show/hide UI elements based on subscription

```dart
// In your widget build method
FutureBuilder<bool>(
  future: SubscriptionChecker.instance.isSecurePlan(),
  builder: (context, snapshot) {
    if (snapshot.data == true) {
      return ElevatedButton(
        onPressed: () => _useAdvancedFeature(),
        child: Text('Use Advanced Feature'),
      );
    } else {
      return OutlinedButton(
        onPressed: () => _showUpgradeDialog(),
        child: Text('Upgrade to Unlock'),
      );
    }
  },
)
```

### 6. Check subscription expiry

```dart
final isExpiring = await SubscriptionChecker.instance.isSubscriptionExpiringSoon(daysThreshold: 7);
if (isExpiring) {
  // Show renewal reminder
  _showRenewalReminder();
}

final isExpired = await SubscriptionChecker.instance.isSubscriptionExpired();
if (isExpired) {
  // Restrict access to premium features
}
```

## Available Features

Features are determined by **plan tier** (Free vs Paid), not specific plan names:

### Free Tier Features (price = 0)
- `amendments` - Unlimited amendments
- `digital_will_generator` - Generate digital will
- `24_hours_access` - 24/7 access
- Assets: Up to 5

### Paid Tier Features (price > 0)
Includes all Free features **plus**:
- `nazar_fidyah_clause` - Nazar/Fidyah clause
- `one_third_to_non_waris` - 1/3 to non-waris
- `charity_sadaqah_waqf_clause` - Charity/Sadaqah/Waqf clause
- `organ_donation_clause` - Organ donation clause
- `post_loss_guidance` - 30 minutes post-loss guidance
- `appointment_of_guardian` - Appointment of Guardian
- `appointment_of_co_sampul` - Appointment of Co-Sampul (2)
- `digital_certificate` - Digital Wasiat/Will Certificate
- `digital_with_witnesses` - Digital Wasiat/Will with witnesses & timestamp
- `simplified_dashboard` - Simplified Dashboard
- `support` - Support
- `unlimited_assets` - Unlimited assets

## Adding New Plans

The system automatically supports new plans without code changes:

1. **Create the plan in Stripe** - Add a new product/price
2. **Set the price amount**:
   - `0` = Free tier (basic features)
   - `> 0` = Paid tier (all features)
3. **That's it!** The app will automatically:
   - Show the plan in the billing screen
   - Allow users to subscribe
   - Apply correct feature gating based on tier

### Example: Adding a "Premium Plan"

1. In Stripe Dashboard → Create new product "Premium Plan" with price `RM 300/year`
2. The app automatically:
   - Lists it in Billing & Plans screen
   - Users can subscribe
   - `getPlanTier()` returns `'paid'` (because price > 0)
   - All premium features are unlocked

No code changes needed! 🎉

## Real-World Examples

### Example 1: Asset List Screen

```dart
class AssetsListScreen extends StatefulWidget {
  @override
  State<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> {
  int _assetCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    // Load your assets
    setState(() => _assetCount = assets.length);
  }

  Future<void> _addAsset() async {
    final canAdd = await SubscriptionChecker.instance.canAddAsset(
      currentAssetCount: _assetCount,
    );

    if (!canAdd) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Upgrade Required'),
            content: Text('Free plan allows up to 5 assets. Upgrade to Secure plan for unlimited assets.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BillingScreen()),
                  );
                },
                child: Text('Upgrade'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Proceed with adding asset
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAssetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assets')),
      body: ListView(
        children: [
          // Your asset list
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAsset,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Example 2: Will Generation Screen

```dart
class WillGenerationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate Will')),
      body: ListView(
        children: [
          // Basic features (available to all)
          _buildBasicFeatures(),
          
          // Advanced features (Secure plan only)
          FutureBuilder<bool>(
            future: SubscriptionChecker.instance.hasFeature('nazar_fidyah_clause'),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return _buildAdvancedFeatures();
              } else {
                return _buildUpgradeCard(
                  title: 'Nazar/Fidyah Clause',
                  message: 'Upgrade to Secure plan to unlock this feature',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### Example 3: Settings Screen with Subscription Status

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // Show current subscription status
          FutureBuilder<BillingStatus>(
            future: SubscriptionChecker.instance.getStatus(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final status = snapshot.data!;
                return ListTile(
                  leading: Icon(Icons.credit_card),
                  title: Text('Subscription'),
                  subtitle: Text(
                    status.isSubscribed
                        ? '${status.planName ?? "Active"} - ${status.status}'
                        : 'No active subscription',
                  ),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BillingScreen()),
                  ),
                );
              }
              return ListTile(
                leading: Icon(Icons.credit_card),
                title: Text('Subscription'),
                subtitle: Text('Loading...'),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

## Caching

The subscription status is cached for 5 minutes to avoid excessive API calls. To force a refresh:

```dart
final status = await SubscriptionChecker.instance.getStatus(forceRefresh: true);
```

To clear cache (e.g., after subscription changes):

```dart
SubscriptionChecker.instance.clearCache();
```

## Best Practices

1. **Check subscription at screen entry** - Load status in `initState()` for screens that need it
2. **Show upgrade prompts** - Don't just hide features, guide users to upgrade
3. **Cache wisely** - Use the built-in cache, but refresh after subscription changes
4. **Handle loading states** - Use `FutureBuilder` to show loading while checking subscription
5. **Graceful degradation** - Show free features even if subscription check fails

## Integration with Billing Screen

After user subscribes or changes plan, clear the cache:

```dart
// In billing_screen.dart, after successful subscription
await SubscriptionChecker.instance.getStatus(forceRefresh: true);
// or
SubscriptionChecker.instance.clearCache();
```

This ensures the rest of the app immediately reflects the new subscription status.

