class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.string :name
      t.string :url
      t.string :img_url
      t.string :price
      t.string :type
      t.text   :rules
      t.string :editions
      t.string :formats
      t.string :rulings


      t.timestamps

    end
  end
end
