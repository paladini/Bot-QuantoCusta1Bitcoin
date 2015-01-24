# #encoding: utf-8
# require 'twitter'
# require 'httparty'

# ### CONFIGURAÇÕES BÁSICAS ###
# @mensagem_post = "Quanto está custando <%quantidade%> BTC agora? Na Foxbit custa apenas R$<%preco%>! #bitcoin #foxbit"
# @mensagem_resposta = "Olá <%username%>, a cotação de <%quantidade%> BTC é R$<%preco%>. Você já conhece a Foxbit, a exchange mais adorada do Brasil?"
# @quantidade = 1.0

# ### CONFIGURAÇÕES AVANÇADAS ###
# @url_api = "https://quantocusta1bitcoin.herokuapp.com/api/v1/cotacao"
# cliente = Twitter::REST::Client.new do |config|
#   config.consumer_key = ENV['CONSUMER_KEY']
#   config.consumer_secret = ENV['CONSUMER_SECRET']
#   config.access_token = ENV['ACCESS_TOKEN']
#   config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
# end



namespace :bot do

  desc "Tarefa responsável por iniciar os bots do sistema."
  task start: :environment do

    # Criando tarefa agendada para realizar Posts no Twitter.
    # É nessa primeira linha que é definida a cron task.
    post_worker = Sidekiq::Cron::Job.new(name: 'Post Worker - A cada 30min', cron: '*/30 * * * *', klass: 'PostWorker', retry: 'true')
    if post_worker.save
        puts "==============================================="
        puts " CronJob \"HardWorker\" criado com sucesso."
        puts "==============================================="
    else
        puts "====================="
        puts post_worker.errors
        puts "====================="
    end
    post_worker.enque!

    # Criando tarefa agendada para responder tweets (replies).
    reply_worker = Sidekiq::Cron::Job.new(name: 'Reply Worker - A cada min', cron: '* * * * *', klass: 'ReplyWorker')
    if reply_worker.save
        puts "==============================================="
        puts " CronJob \"reply_worker\" criado com sucesso."
        puts "==============================================="
    else
        puts "====================="
        puts reply_worker.errors
        puts "====================="
    end
    reply_worker.enque!

  end

  #cliente.update("Olá @#{mentions[0].user.screen_name}, um bitcoin está valendo R$680,00.", in_reply_to_status_id: mentions[0].id)


  # desc "Responde aos tweets dos usuários com a cotação do BTC."
  # task reply: :environment do
  #   puts "Passou pela tarefa reply!"
  #   # Pegando cada menção
  #   # begin
  #   #   puts cliente.mentions_timeline[0].to_s
  #   # rescue Timeout::Error, Twitter::Error => error
  #   #   if error.is_a?(Timeout::Error) || error.cause.is_a?(Timeout::Error) || error.cause.is_a?(Faraday::Error::TimeoutError)
  #   #     retry
  #   #   else
  #   #     raise
  #   #   end
  #   # end
  #   #cliente.mentions_timeline.each do |mention|

  #   #end

  # end

  # desc "Faz posts no Twitter do 'Quanto Custa 1 Bitcoin?' a cada 30 minutos."
  # task post: :environment do

  #   # Pega cotação na API do "Quanto Custa 1 Bitcoin?"
  #   cotacao_atual = checar_cotacao()

  #   # Formata mensagem com cotação atual
  #   mensagem_formatada = inserir_valores_post(cotacao_atual)

  #   # Envia mensagem para o Twitter
  #   begin
  #     cliente.update(mensagem_formatada)
  #   rescue Timeout::Error, Twitter::Error => error
  #     if error.is_a?(Timeout::Error) || error.cause.is_a?(Timeout::Error) || error.cause.is_a?(Faraday::Error::TimeoutError)
  #       retry
  #     else
  #       raise
  #     end
  #   end

  #   # Posta uma mensagem no terminal alertando sobre o post no Twitter.
  #   data = Time.now.strftime("%e %b %Y %H:%M:%S%p")
  #   Rails.logger.info("Postado no Twitter em #{data}: \"#{mensagem_formatada}\"")

  # end

  # # Checa a cotação do Bitcoin na Foxbit utilizando a API fornecida pelo "Quanto Custa 1 Bitcoin?". A cotação do preço do Bitcoin é baseada no Orderbook e na quantidade de Bitcoins requerida. O valor padrão para a quantidade de bitcoins é 1, mas isso é facilmente customizáve (já deixei preparado para tal mudança, caso seja necessária).
  # def checar_cotacao(quantidade = @quantidade)

  #   # Acessando API do "Quanto Custa 1 Bitcoin?".
  #   response = HTTParty.post(@url_api, :query => { :amount => quantidade})

  #   # Requisição teve sucesso?
  #   if response.success?
  #     json = JSON.parse(response.body)

  #     # Checando se existe um valor não nulo para a chave "price" do JSON
  #     if json.has_key?("price")
  #       return json["price"]
  #     else
  #       raise "Chave ['price'] do JSON nula!"
  #     end
  #   else
  #     raise response.response
  #   end

  # end

  # # Método responsável por inserir os valores de preço e quantidade na "frase padrão" de post da cotação no Twitter.
  # def inserir_valores_post(preco=nil, quantidade=@quantidade)
  #   mensagem = @mensagem_post.sub("<%quantidade%>", quantidade.to_s)
  #   mensagem = mensagem.sub("<%preco%>", preco.to_s)
  #   return mensagem
  # end

  # # Método responsável por inserir os valores de preço, quantidade e nome de usuário na "frase padrão" de responder pessoas no Twitter.
  # def inserir_valores_resposta(preco=nil, username=nil, quantidade=@quantidade)
  #   mensagem = @mensagem_resposta.sub("<%quantidade%>", quantidade.to_s)
  #   mensagem = mensagem.sub("<%preco%>", preco.to_s)
  #   mensagem = mensagem.sub("<%username%>", username.to_s)
  #   return mensagem
  # end

end
