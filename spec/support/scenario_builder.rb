module ScenarioBuilder
  def build_learning_scenario(suffix: SecureRandom.hex(4))
    organization = Organization.create!(name: "Northstar #{suffix}", slug: "northstar-#{suffix}")
    school = organization.schools.create!(name: "Riverside School", slug: "riverside")
    teacher = User.create!(
      name: "Jordan Lee",
      email_address: "teacher-#{suffix}@example.test",
      password: "test-password"
    )
    Membership.create!(organization:, school:, user: teacher, role: "teacher")
    course = Course.create!(
      organization:,
      school:,
      name: "Algebra I",
      code: "ALG1-#{suffix}",
      subject: "Mathematics",
      grade_level: "9"
    )
    section = Section.create!(
      organization:,
      school:,
      course:,
      teacher:,
      name: "Period 2",
      academic_term: "2026–27"
    )
    student = Student.create!(
      organization:,
      school:,
      external_ref: "student-#{suffix}",
      first_name: "Maya",
      last_initial: "R",
      synthetic: true
    )
    Enrollment.create!(organization:, section:, student:)
    objective = LearningObjective.create!(
      organization:,
      course:,
      code: "ALG1.F-IF.6-#{suffix}",
      title: "Interpret slope as rate of change",
      description: "Calculate and interpret the average rate of change of a function."
    )
    MasterySnapshot.create!(organization:, student:, learning_objective: objective, score: 78, observed_on: 14.days.ago.to_date, source: "assessment")
    MasterySnapshot.create!(organization:, student:, learning_objective: objective, score: 61, observed_on: 2.days.ago.to_date, source: "assessment")

    document = CurriculumDocument.create!(
      organization:,
      course:,
      learning_objective: objective,
      title: "Algebra I Unit 4",
      source_label: "District curriculum"
    )
    provider = Ai::Providers::DeterministicProvider.new
    contents = [
      "Slope is the ratio of vertical change to horizontal change. Keep slope and the y-intercept labeled separately.",
      "When given two points, subtract coordinates in a consistent order before simplifying the slope ratio.",
      "Check understanding across graphs, tables, and equations with a short exit ticket."
    ]
    embeddings = provider.embed(model: "test-embedding", inputs: contents)
    contents.each_with_index do |content, index|
      DocumentChunk.create!(
        organization:,
        curriculum_document: document,
        learning_objective: objective,
        content:,
        locator: "Lesson 4.#{index + 1}",
        token_count: content.split.size,
        embedding: embeddings[index]
      )
    end
    document.update!(chunk_count: contents.size)

    signal = Signals::Detect.new(section:).call.fetch(0)
    {
      organization:,
      school:,
      teacher:,
      course:,
      section:,
      student:,
      objective:,
      signal:
    }
  end
end
