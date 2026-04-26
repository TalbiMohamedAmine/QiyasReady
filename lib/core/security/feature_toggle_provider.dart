import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/subscriptions/providers/subscriptions_provider.dart';

class FeatureToggles {
  const FeatureToggles({
    required this.isAiSolutionsEnabled,
    required this.isTimeSeriesEnabled,
    required this.isFlightModeEnabled,
    required this.isGlobalMistakesFullyUnlocked,
    required this.isWellbeingEnabled,
    required this.hasPurchasedReport,
  });

  final bool isAiSolutionsEnabled;
  final bool isTimeSeriesEnabled;
  final bool isFlightModeEnabled;
  final bool isGlobalMistakesFullyUnlocked;
  final bool isWellbeingEnabled;
  final bool hasPurchasedReport;
}

final featureToggleProvider = Provider<FeatureToggles>((ref) {
  final plan = ref.watch(userPlanProvider).valueOrNull ?? UserPlan.beginner;
  
  final isBasic = plan == UserPlan.basic;
  final isExpert = plan == UserPlan.expert;
  final isPremium = isBasic || isExpert;

  return FeatureToggles(
    isAiSolutionsEnabled: isExpert,
    isTimeSeriesEnabled: isExpert,
    isFlightModeEnabled: isPremium,
    isGlobalMistakesFullyUnlocked: isExpert,
    isWellbeingEnabled: isExpert,
    hasPurchasedReport: isExpert,
  );
});
