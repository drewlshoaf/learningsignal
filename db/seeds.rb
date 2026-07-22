organization = Organization.find_or_create_by!(slug: "northstar-learning") do |record|
  record.name = "Northstar Learning Collaborative"
end

school = School.find_or_create_by!(organization: organization, slug: "riverside") do |record|
  record.name = "Riverside Academy"
end

teacher = User.find_or_initialize_by(email_address: "teacher@learningsignal.test")
teacher.assign_attributes(name: "Jordan Lee", password: "learning-signal-demo", password_confirmation: "learning-signal-demo")
teacher.save!

Membership.find_or_create_by!(organization: organization, school: school, user: teacher) do |record|
  record.role = "teacher"
end

course = Course.find_or_create_by!(organization: organization, code: "ALG1") do |record|
  record.school = school
  record.name = "Algebra I"
  record.subject = "Mathematics"
  record.grade_level = "9"
end

section = Section.find_or_create_by!(organization: organization, course: course, name: "Period 2") do |record|
  record.school = school
  record.teacher = teacher
  record.academic_term = "Fall 2026"
end

objective = LearningObjective.find_or_create_by!(organization: organization, code: "ALG1.LIN.3") do |record|
  record.course = course
  record.title = "Interpret slope and y-intercept"
  record.description = "Interpret the rate of change and initial value of a linear relationship across graphs, tables, and equations."
end

student_names = [ [ "Maya", "R" ], [ "Eli", "T" ], [ "Noah", "K" ], [ "Amara", "S" ], [ "Sofia", "M" ], [ "Theo", "B" ] ]
students = student_names.each_with_index.map do |(first_name, last_initial), index|
  Student.find_or_create_by!(organization: organization, external_ref: "SYN-#{1001 + index}") do |record|
    record.school = school
    record.first_name = first_name
    record.last_initial = last_initial
    record.synthetic = true
  end.tap do |student|
    Enrollment.find_or_create_by!(organization: organization, section: section, student: student)
  end
end

maya = students.first
[ [ 3.weeks.ago.to_date, 78, "Unit 2 checkpoint" ], [ 2.days.ago.to_date, 61, "Linear relationships quiz" ] ].each do |observed_on, score, source|
  MasterySnapshot.find_or_create_by!(organization: organization, section: section, student: maya, learning_objective: objective, observed_on: observed_on, source: source) do |record|
    record.score = score
  end
end

students.drop(1).each_with_index do |student, index|
  [ [ 3.weeks.ago.to_date, 72 + index ], [ 2.days.ago.to_date, 75 + index ] ].each do |observed_on, score|
    MasterySnapshot.find_or_create_by!(organization: organization, section: section, student: student, learning_objective: objective, observed_on: observed_on, source: "Synthetic mastery check") do |record|
      record.score = score
    end
  end
end

assessment = Assessment.find_or_initialize_by(organization: organization, external_ref: "ALG1-LIN-CHECK")
assessment.assign_attributes(
  course: course,
  title: "Linear Relationships Check",
  assessment_type: "quiz",
  status: "published",
  synthetic: true
)
assessment.save!

question_data = [
  [ "Q1", "Find slope from two points", "B", 1 ],
  [ "Q2", "Distinguish slope from y-intercept", "C", 1 ],
  [ "Q3", "Identify the rate of change", "4", 1 ]
]
questions = question_data.map do |external_ref, prompt_reference, answer_key, maximum_points|
  assessment.assessment_questions.find_or_initialize_by(external_ref:).tap do |question|
    question.assign_attributes(
      organization: organization,
      learning_objective: objective,
      prompt_reference:,
      question_type: "multiple_choice",
      maximum_points:,
      metadata: { "answer_key" => answer_key }
    )
    question.save!
  end
end
assessment.recalculate_maximum_score!

attempt = AssessmentAttempt.find_or_initialize_by(
  organization: organization,
  section: section,
  external_ref: "SYN-1001-LIN-1"
)
attempt.assign_attributes(
  student: maya,
  assessment: assessment,
  attempt_number: 1,
  started_at: 1.day.ago.change(hour: 14),
  submitted_at: 1.day.ago.change(hour: 14, min: 20),
  status: "submitted",
  synthetic: true
)
attempt.save!

[ "B", "A", "0" ].each_with_index do |answer, index|
  question = questions.fetch(index)
  correct = answer.casecmp?(question.answer_key)
  response = attempt.question_responses.find_or_initialize_by(assessment_question: question)
  response.assign_attributes(
    organization: organization,
    selected_answer: answer,
    correct:,
    points_earned: correct ? question.maximum_points : 0,
    submitted_at: attempt.submitted_at
  )
  response.save!
end
attempt.recalculate_score!

assessment_snapshot = MasterySnapshot.find_or_initialize_by(
  organization: organization,
  section: section,
  student: maya,
  learning_objective: objective,
  observed_on: attempt.submitted_at.to_date,
  source: "Assessment attempt #{attempt.external_ref}"
)
assessment_snapshot.score = attempt.percentage
assessment_snapshot.save!

document = CurriculumDocument.find_or_create_by!(organization: organization, course: course, title: "Algebra I · Linear Relationships") do |record|
  record.source_label = "Northstar Mathematics Curriculum, Unit 2"
  record.status = "ready"
end
document.update!(learning_objective: objective, status: "ready")

chunks = [
  [ "Lesson 2.3", "Slope describes the rate of change between two quantities. From two points, subtract the y-values to find rise and subtract the x-values in the same order to find run. The y-intercept is a different quantity: it is where the line crosses the vertical axis." ],
  [ "Worked example 2.3A", "For the points (1, 3) and (4, 9), rise is 9 minus 3 and run is 4 minus 1, so slope is 2. In the equation y = 2x + 1, the slope is 2 while the y-intercept is 1." ],
  [ "Practice set 4B", "Ask students to match graphs, tables, and equations for the same linear relationship. Require separate labels for rate of change and initial value before computing either quantity." ]
].map do |locator, content|
  DocumentChunk.find_or_create_by!(organization: organization, curriculum_document: document, locator: locator) do |record|
    record.learning_objective = objective
    record.content = content
    record.token_count = content.split.size
    record.metadata = { grade_level: "9", subject: "mathematics" }
  end
end

provider = Ai::Providers::DeterministicProvider.new
embeddings = provider.embed(model: Ai::Configuration.embedding_model, inputs: chunks.map(&:content))
chunks.zip(embeddings).each { |chunk, embedding| chunk.update!(embedding: embedding) if chunk.embedding.blank? }
document.update!(chunk_count: chunks.size)

signal = Signals::Detect.new(section: section).call.first || section.student_signals.order(:created_at).first

investigation = signal.investigations.find_or_initialize_by(teacher: teacher)
if investigation.new_record?
  investigation.assign_attributes(
    organization: organization,
    school: school,
    status: "queued",
    current_step: "queued"
  )
  investigation.save!
end
Investigations::Orchestrator.new(investigation: investigation, provider: provider).call unless investigation.status == "completed"

plan = investigation.intervention_plan
unless plan.status == "approved"
  plan.update!(status: "approved", approved_at: 1.day.ago)
  plan.teacher_decisions.find_or_create_by!(organization: organization, user: teacher, decision: "approved") do |decision|
    decision.plan_snapshot = plan.snapshot
  end
end

InterventionOutcomes::Record.call(
  outcome: plan.intervention_outcome || plan.build_intervention_outcome,
  actor: teacher,
  attributes: {
    status: "completed",
    effectiveness: "effective",
    follow_up_mastery_score: 76,
    teacher_assessment: "Maya now distinguishes slope from the y-intercept across graphs and equations. One more table-based check will confirm transfer.",
    student_completed: true,
    notes: "Continue with the scheduled reassessment next week."
  },
  completed_action_ids: plan.intervention_actions.limit(2).pluck(:id)
)

puts "Seeded LearningSignal with #{students.size} synthetic students, #{AssessmentAttempt.count} assessment attempt, #{StudentSignal.count} academic signal, and #{InterventionOutcome.count} intervention outcome."
puts "Sign in with teacher@learningsignal.test / learning-signal-demo"
