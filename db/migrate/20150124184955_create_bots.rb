#
###
### Migração que cria a única tabela do banco de dados até o momento
###
#
# Cria uma tabela com apenas um campo (ao menos oficialmente): o Rails cria
# mais 3 campos para essa tabela:
#
#   id(integer): ID, como de qualquer tabela de banco de dados.
#   created_at(timestamp): Quando o dado atual foi criado na tabela.
#   updated_at(timestamp): Quando o dado atual foi atualizado pela última vez
#                          nessa tabela.
#
# Logo abaixo dessa migração tem um método que já popula o banco de dados
# criando dois registros:
#
#       {"id": 1, "description":"post" }
#       {"id": 2, "description":"reply"}
#
# Cada um desses registros será responsável por armazenar a última vez
# que esse dado foi atualizado no banco de dados. O exemplo mais claro é
# utilizando o registro "reply":
#
#   * Utilizando o campo updated_at do registro "reply" é possível saber
#   quando foi o último tweet feito pelo robô, ou seja, podemos deduzir
#   que a partir dessa data ele ainda não respondeu mais nenhum tweet.
#   Dessa forma podemos saber quais menções ao Bot já foram respondidas
#   e quais ainda não foram.
#
#
##
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
