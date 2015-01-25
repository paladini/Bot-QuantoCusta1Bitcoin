#encoding: utf-8
#
###
### Bot responsável por fazer posts periódicos no Twitter.
###
#
# Esse "worker" é responsável por fazer posts periódicos no Twitter utilizando
# a cotação do BTC na Foxbit. De acordo com as configurações em
# "/lib/tasks/bot.rake", esse bot será executado a cada 30 minutos. Caso
# ocorra algum erro no processo, o comando "sidekiq_options :retry => 3"
# garante que esse mesmo script vai ser executado 3 vezes antes de ser
# considerado morto (considerando que em todas as 3 vezes que seja executado
# aconteceria algum erro).
#
# O seu funcionamento é simples e depende de um banco de dados Postgresql para
# funcionar corretamente. Os passos do algoritmo, de forma resumida, são os
# que seguem:
#
#   1. Obtem a cotação atual da Foxbit para 1 BTC utilizando a API do
#      projeto "Quanto Custa 1 Bitcoin?".
#   2. Formata a mensagem de post baseado no "template" de mensagem chamado
#      "@mensagem_post" que está localizado em "app/workers/util.rb".
#   3. Envia mensagem ao Twitter.
#   4. Atualiza banco de dados com a data deste último post no Twitter.
#   5. Para finalizar, o bot gera algumas mensagens no Logger do Rails, que
#      ficarão armazenados em um arquivo chamado "production.log", lá no
#      servidor do Heroku.
#
# Bot.find(1) => está procurando no banco de dados o registro de ID 1, que
# nesse caso seria o dado com a data do último POST feito pelo Bot no Twitter.
# Dúvidas, veja o banco de dados do Postgresql e verá que só tem duas linhas
# adicionadas na tabela (ou seja, dois dados, o com ID=1 e o com ID=2).
#
# [OBS] Vale constar que o dado da última RESPOSTA no Twitter é DIFERENTE
#       do dado do último POST no Twitter.
#
##
require 'util'

class PostWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3

  def perform()

    # Pega cotação na API do "Quanto Custa 1 Bitcoin?"
    cotacao_atual = Util::checar_cotacao()

    # Formata mensagem com cotação atual
    mensagem_formatada = Util::inserir_valores_post(cotacao_atual)

    # Salva o horário do evento.
    horario = nil

    # Envia mensagem para o Twitter
    begin

      # Enviando mensagem e obtendo data de criação do tweet.
      horario = Util::cliente.update(mensagem_formatada).created_at

      # Atualizando banco de dados
      Bot.find(1).update_column(:updated_at, horario)

    rescue Timeout::Error, Twitter::Error => error
      if error.is_a?(Timeout::Error) || error.cause.is_a?(Timeout::Error) || error.cause.is_a?(Faraday::Error::TimeoutError)
        retry
      else
        raise
      end
    end

    # Posta uma mensagem no terminal alertando sobre o post no Twitter.
    data = horario.strftime("%e %b %Y %H:%M:%S%p")
    Rails.logger.info("[INFO] Postado no Twitter em #{data}: \"#{mensagem_formatada}\"")

  end
end
