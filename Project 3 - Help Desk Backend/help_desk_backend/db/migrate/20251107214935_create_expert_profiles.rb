class CreateExpertProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :expert_profiles do |t|
      t.text :bio
      t.json :knowledge_base_links
      t.references :user, null: false, foreign_key: true, index: {unique: true}
      t.timestamps
    end
  end
end
