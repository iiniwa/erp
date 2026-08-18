class CreateCodeSequences < ActiveRecord::Migration[8.1]
  def change
    # id: false: sequence_key is the primary key directly. A separate
    # AUTO_INCREMENT id column would make MySQL's bare `LAST_INSERT_ID()`
    # (used by CodeSequence.next_number_for) return that column's generated
    # value instead of the `last_number` we assign explicitly.
    create_table :code_sequences, id: false do |t|
      t.string :sequence_key, null: false
      t.bigint :last_number, null: false, default: 0

      t.timestamps
    end

    execute "ALTER TABLE code_sequences ADD PRIMARY KEY (sequence_key)"
  end
end
