$ErrorActionPreference = 'Stop'

# Run this from your project root (the folder that contains lib/)
$root = Join-Path (Get-Location) 'lib'

$dirs = @(
  'app',
  'core',
  'core/constants',
  'core/errors',
  'core/firebase',
  'core/state',
  'core/theme',
  'core/utils',
  'shared',
  'shared/widgets',
  'shared/models',
  'shared/services',
  'features',

  'features/auth',
  'features/auth/screens',
  'features/auth/providers',
  'features/auth/models',
  'features/auth/repositories',

  'features/onboarding',
  'features/onboarding/screens',
  'features/onboarding/providers',
  'features/onboarding/models',

  'features/exam_engine',
  'features/exam_engine/screens',
  'features/exam_engine/providers',
  'features/exam_engine/models',

  'features/adaptive_practice',
  'features/adaptive_practice/screens',
  'features/adaptive_practice/providers',
  'features/adaptive_practice/models',

  'features/custom_tests',
  'features/custom_tests/screens',
  'features/custom_tests/providers',
  'features/custom_tests/models',

  'features/analytics',
  'features/analytics/screens',
  'features/analytics/providers',
  'features/analytics/models',

  'features/question_explanations',
  'features/question_explanations/screens',
  'features/question_explanations/providers',
  'features/question_explanations/models',

  'features/subscriptions',
  'features/subscriptions/screens',
  'features/subscriptions/providers',
  'features/subscriptions/models',

  'features/goals',
  'features/goals/screens',
  'features/goals/providers',
  'features/goals/models',

  'features/notifications',
  'features/notifications/screens',
  'features/notifications/providers',
  'features/notifications/models',

  'features/offline_mode',
  'features/offline_mode/screens',
  'features/offline_mode/providers',
  'features/offline_mode/models',

  'features/settings',
  'features/settings/screens',
  'features/settings/providers',
  'features/settings/models',

  'features/wellbeing',
  'features/wellbeing/screens',
  'features/wellbeing/providers',
  'features/wellbeing/models',

  'features/security_sync',
  'features/security_sync/screens',
  'features/security_sync/providers',
  'features/security_sync/models'
)

$files = @(
  'app/app.dart',
  'app/router.dart',
  'app/bootstrap.dart',

  'core/firebase/firebase_options.dart',
  'core/firebase/firestore_paths.dart',
  'core/firebase/cloud_functions_client.dart',
  'core/state/auth_state_provider.dart',
  'core/state/connectivity_provider.dart',
  'core/state/app_lifecycle_provider.dart',

  'shared/services/local_cache_service.dart',
  'shared/services/notification_service.dart',

  'features/auth/screens/sign_in_screen.dart',
  'features/auth/screens/sign_up_screen.dart',
  'features/auth/providers/auth_provider.dart',
  'features/auth/auth_service.dart',

  'features/onboarding/screens/welcome_screen.dart',
  'features/onboarding/screens/plan_selection_screen.dart',
  'features/onboarding/providers/onboarding_provider.dart',
  'features/onboarding/onboarding_service.dart',

  'features/exam_engine/screens/mock_intro_screen.dart',
  'features/exam_engine/screens/exam_runner_screen.dart',
  'features/exam_engine/screens/section_break_screen.dart',
  'features/exam_engine/screens/exam_submit_screen.dart',
  'features/exam_engine/providers/exam_session_provider.dart',
  'features/exam_engine/providers/exam_timer_provider.dart',
  'features/exam_engine/models/exam_session.dart',
  'features/exam_engine/models/answer_payload.dart',
  'features/exam_engine/exam_engine_service.dart',

  'features/adaptive_practice/screens/practice_filter_screen.dart',
  'features/adaptive_practice/screens/practice_runner_screen.dart',
  'features/adaptive_practice/providers/adaptive_practice_provider.dart',
  'features/adaptive_practice/adaptive_practice_service.dart',

  'features/custom_tests/screens/custom_test_builder_screen.dart',
  'features/custom_tests/screens/custom_test_runner_screen.dart',
  'features/custom_tests/providers/custom_tests_provider.dart',
  'features/custom_tests/custom_tests_service.dart',

  'features/analytics/screens/dashboard_screen.dart',
  'features/analytics/screens/session_review_screen.dart',
  'features/analytics/screens/common_mistakes_screen.dart',
  'features/analytics/providers/analytics_provider.dart',
  'features/analytics/analytics_service.dart',

  'features/question_explanations/screens/explanation_detail_screen.dart',
  'features/question_explanations/providers/question_explanations_provider.dart',
  'features/question_explanations/question_explanations_service.dart',

  'features/subscriptions/screens/paywall_screen.dart',
  'features/subscriptions/screens/plan_comparison_screen.dart',
  'features/subscriptions/providers/subscriptions_provider.dart',
  'features/subscriptions/subscriptions_service.dart',

  'features/goals/screens/goal_setup_screen.dart',
  'features/goals/screens/goals_progress_screen.dart',
  'features/goals/providers/goals_provider.dart',
  'features/goals/goals_service.dart',

  'features/notifications/screens/notifications_settings_screen.dart',
  'features/notifications/providers/notifications_provider.dart',
  'features/notifications/notifications_service.dart',

  'features/offline_mode/screens/offline_downloads_screen.dart',
  'features/offline_mode/screens/sync_status_screen.dart',
  'features/offline_mode/providers/offline_mode_provider.dart',
  'features/offline_mode/offline_mode_service.dart',

  'features/settings/screens/appearance_settings_screen.dart',
  'features/settings/screens/exam_layout_settings_screen.dart',
  'features/settings/providers/settings_provider.dart',
  'features/settings/settings_service.dart',

  'features/wellbeing/screens/wellbeing_home_screen.dart',
  'features/wellbeing/screens/breathing_exercise_screen.dart',
  'features/wellbeing/providers/wellbeing_provider.dart',
  'features/wellbeing/wellbeing_service.dart',

  'features/security_sync/screens/device_sync_screen.dart',
  'features/security_sync/providers/security_sync_provider.dart',
  'features/security_sync/security_sync_service.dart'
)

# Create directories
foreach ($d in $dirs) {
  $path = Join-Path $root $d
  if (-not (Test-Path $path)) {
    New-Item -Path $path -ItemType Directory -Force | Out-Null
  }
}

# Create empty .dart files (without overwriting existing content)
foreach ($f in $files) {
  $path = Join-Path $root $f
  if (-not (Test-Path $path)) {
    New-Item -Path $path -ItemType File -Force | Out-Null
  }
}

Write-Host "Done. Flutter feature structure created under: $root"