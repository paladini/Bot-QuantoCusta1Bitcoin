#encoding: utf-8
#
###
### Bot responsável por responder menções.
###
#
# Esse "worker" é responsável por responder todas as menções que o Bot receber
# pelo Twitter. De acordo com as configurações em /lib/tasks/bot.rake, esse
# bot será executado a cada minutos. Desabilitei os "retries" em caso de erro
# pois o código será executado a cada minuto, se um deles tiver erro não
# tem problema, pois no minuto seguinte já terá outro. Ao acontecer um erro a
# tarefa vai ser considerada "morta" (dead task).
#
# O seu funcionamento é simples e depende de um banco de dados Postgresql para
# funcionar corretamente. Os passos do algoritmo, de forma resumida, são os
# que seguem:
#
#   1. Obtem TODAS as menções feitas ao Bot no Twitter.
#   2. Pega no banco de dados a última vez que o Bot respondeu alguém no
#      Twitter.
#   3. Verifica as menções de acordo com configuração @participar_de_conversas
#      no arquivo "app/workers/util.rb". Se o bot:
#
#         a) Precisa responder à conversas: quaisquer menções feitas DEPOIS do
#            último post do Bot no Twitter devem ser respondidas.
#         b) Precisa responder à conversas (padrão): apenas as menções
#            feitas DEPOIS do último post do Bot no Twitter devem ser
#            respondidas.
#   4. Após ser criada a lista de menções que precisam ser respondidas, uma
#      iteração ao contrário é feita no vetor para que as respostas sejam
#      feitas da mais antiga para a mais nova.
#   5. As mensagens de cada resposta são geradas baseada em um "template" de
#      mensagem chamado "@mensagem_resposta" localizado no arquivo
#      "app/workers/util.rb". Após isso a mensagem é enviada ao Twitter.
#   6. A última resposta (ou a mais recente) é armazenada e a sua data
#      de criação é utilizada para atualizar o banco de dados como a última
#      data de uma mensagem enviada pelo bot.
#   7. Para finalizar, o bot gera algumas mensagens no Logger do Rails, que
#      ficarão armazenados em um arquivo chamado "production.log", lá no
#      servidor do Heroku.
#
# Bot.find(2) => está procurando no banco de dados o registro com ID 2, que
# seria justamente o registro com a data de última RESPOSTA no Twitter.
# Dúvidas, veja o banco de dados do Postgresql e verá que só tem duas linhas
# adicionadas na tabela (ou seja, dois dados, o com ID=1 e o com ID=2).
#
# [OBS] Vale constar que o dado da última RESPOSTA no Twitter é DIFERENTE
#       do dado do último POST no Twitter.
#
##
require 'util'

class ReplyWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform()

    # Pegando todas as menções do Twitter
    begin
      mencoes = Util::cliente.mentions
    rescue Timeout::Error, Twitter::Error => error
      if error.is_a?(Timeout::Error) || error.cause.is_a?(Timeout::Error) || error.cause.is_a?(Faraday::Error::TimeoutError)
        raise
      else
        raise
      end
    end

    # Consulta no banco de dados a data da última resposta dada pelo Bot
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
            raise
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
