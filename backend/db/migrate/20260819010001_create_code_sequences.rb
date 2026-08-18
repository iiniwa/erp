class CreateCodeSequences < ActiveRecord::Migration[8.1]
  def change
    # id: false: sequence_key is naturally unique per bucket, so it is the
    # primary key directly rather than adding a redundant surrogate id.
    create_table :code_sequences, id: false do |t|
      t.string :sequence_key, null: false
      t.bigint :last_number, null: false, default: 0

      t.timestamps
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE code_sequences ADD PRIMARY KEY (sequence_key)" }
      dir.down { execute "ALTER TABLE code_sequences DROP PRIMARY KEY" }
    end
  end
end
