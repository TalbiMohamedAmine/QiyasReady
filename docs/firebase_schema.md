1. COLLECTION: /users/{uid}
  profile:
    fullName
    examTarget
    locale
  settings: (theme, layout, etc.)
  entitlement: (tier, trial status, etc.)
  global_stats:           <-- FRIEND'S ADDITION (1-read Dashboard)
    total_questions_answered
    overall_accuracy
    avg_solve_time
  ai_summary_cache:       <-- FRIEND'S ADDITION (Cost Saver)
    last_feedback_text
    generated_at
  streak: (currentDays, etc.)

2. COLLECTION: /questions/{questionId}  (Friend's "content_bank")
  examId
  chapterId
  lessonId
  difficulty
  stem
  options[]
  correctOptionId
  static_explanation      <-- Default human fallback
  ai_explanation_prompt   <-- FRIEND'S ADDITION (Pre-calculated prompt template)
  avgSolveSec

3. COLLECTION: /users/{uid}/sessions/{sessionId} (Friend's "user_activity")
  mode (mock/adaptive)
  startedAt
  state (in_progress/submitted)
  score: (total, correct, wrong)
  ai_analysis_status      <-- FRIEND'S ADDITION (pending/ready)
  ai_critique:            <-- FRIEND'S ADDITION (Overall session feedback)
    summary
    weak_points[]

4. SUB-COLLECTION: /users/{uid}/sessions/{sessionId}/answers/{questionId}
  // ORIGINAL DESIGN: We keep answers in a sub-collection, NOT an array.
  // This prevents the 1MB document crash limit.
  selectedOption
  isCorrect
  durationSec
  ai_question_feedback    <-- Cache specific question feedback here

5. ADDITIONAL COLLECTIONS (Original MVP Needs)
  /users/{uid}/goals/{goalId}
  /subscription_plans/{planId}
  /wellbeing_content/{contentId}
  /offline_packs/{packId}