class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :email
      t.string :username
      t.string :password

      t.string :fname
      t.string :lname
      t.date :birth_date
      t.string :phone

      t.binary :salt
      t.timestamps
    end
  end
end
