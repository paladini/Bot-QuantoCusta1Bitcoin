class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string :description

      t.timestamps
    end

    # Adiciona os dois bots existentes ("post" e "reply")
    add_default_values()
  end

  def add_default_values
    Bot.create(description: "post")
    Bot.create(description: "reply")
  end
end
