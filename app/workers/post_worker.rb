#encoding: utf-8
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
      # Util::cliente.update(mensagem_formatada)
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
