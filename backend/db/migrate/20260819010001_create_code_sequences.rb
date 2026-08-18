class CreateCodeSequences < ActiveRecord::Migration[8.1]
  def change
    create_table :code_sequences do |t|
      t.string :sequence_key, null: false
      t.bigint :last_number, null: false, default: 0

      t.timestamps
    end

    add_index :code_sequences, :sequence_key, unique: true
  end
end
