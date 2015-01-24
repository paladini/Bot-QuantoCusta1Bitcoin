#encoding: utf-8
require 'util'

class ReplyWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3

  def perform()

    # Pegando todas as menções do Twitter
    begin
      mencoes = Util::cliente.mentions
    rescue Timeout::Error, Twitter::Error => error
      if error.is_a?(Timeout::Error) || error.cause.is_a?(Timeout::Error) || error.cause.is_a?(Faraday::Error::TimeoutError)
        retry
      else
        raise
      end
    end

    # Lendo data da última resposta dada pelo Bot
    data_ultima_resposta = Bot.find(2).updated_at.utc

    # Capturando os tweets que ainda não foram respondidos
    mencoes_nao_respondidas = []
    mencoes.each do |m|

      # Verifica se essa menção ainda não teve resposta.
      if m.created_at.dup.utc >= data_ultima_resposta

        # Bot pode responder conversas? Se sim, já adiciona a menção ao grupo de menções que precisam ser respondidos.
        if Util::participar_de_conversas()
          mencoes_nao_respondidas << m
        else

          # Caso o bot não possa responder conversas, tem que verificar se esse tweet é a resposta à algum outro tweet (o que caracteriza uma conversa)
          if !(m.in_reply_to_status_id?)
            mencoes_nao_respondidas << m
          end

        end
      else
        break
      end
    end

    # Respondendo aos tweets que precisam ser respondidos
    if !mencoes_nao_respondidas.empty?

      # Checando cotação na API
      cotacao_atual = Util::checar_cotacao()

      # Variável para armazenar o último tweet enviado pelo bot.
      ultimo = nil

      # Invertendo a ordem do vetor para responder os tweets mais antigos primeiro.
      mencoes_nao_respondidas.reverse.each do |m|

        # Preparando mensagem para ser enviada.
        mensagem = Util::inserir_valores_resposta(cotacao_atual, m.user.screen_name)

        # Respondendo mensagem ao destinatário.
        begin
          ultimo = Util::cliente.update(mensagem, :in_reply_to_status_id => m.id)
        rescue Timeout::Error, Twitter::Error => error
          if error.is_a?(Timeout::Error) || error.cause.is_a?(Timeout::Error) || error.cause.is_a?(Faraday::Error::TimeoutError)
            retry
          else
            raise
          end
        end

      end

      # Salvando data do último tweet respondido
      Bot.find(2).update_column(:updated_at, ultimo.created_at)

      # Posta uma mensagem no Terminal alertando das respostas.
      data = ultimo.created_at.strftime("%e %b %Y %H:%M:%S%p")
      Rails.logger.info("[INFO] #{mencoes_nao_respondidas.size} pessoa(s) foram respondidas no Twitter entre #{data_ultima_resposta} e #{data}.")

    end

  end
end
