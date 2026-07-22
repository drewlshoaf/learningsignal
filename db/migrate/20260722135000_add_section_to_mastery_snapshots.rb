class AddSectionToMasterySnapshots < ActiveRecord::Migration[8.1]
  def up
    add_reference :mastery_snapshots, :section, foreign_key: true

    execute <<~SQL.squish
      UPDATE mastery_snapshots
      SET section_id = section_matches.section_id
      FROM (
        SELECT mastery_snapshots.id, MIN(sections.id) AS section_id
        FROM mastery_snapshots
        INNER JOIN enrollments
          ON enrollments.student_id = mastery_snapshots.student_id
          AND enrollments.organization_id = mastery_snapshots.organization_id
        INNER JOIN sections
          ON sections.id = enrollments.section_id
          AND sections.organization_id = mastery_snapshots.organization_id
        INNER JOIN learning_objectives
          ON learning_objectives.id = mastery_snapshots.learning_objective_id
          AND learning_objectives.course_id = sections.course_id
        GROUP BY mastery_snapshots.id
        HAVING COUNT(DISTINCT sections.id) = 1
      ) AS section_matches
      WHERE mastery_snapshots.id = section_matches.id
    SQL

    change_column_null :mastery_snapshots, :section_id, false
    add_index :mastery_snapshots,
      [ :organization_id, :section_id, :student_id, :learning_objective_id, :observed_on, :source ],
      unique: true,
      name: "index_mastery_snapshots_on_import_identity"
  end

  def down
    remove_index :mastery_snapshots, name: "index_mastery_snapshots_on_import_identity"
    remove_reference :mastery_snapshots, :section, foreign_key: true
  end
end
