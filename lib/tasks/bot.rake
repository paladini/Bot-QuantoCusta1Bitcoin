#encoding: utf-8
require 'twitter'
require 'httparty'

namespace :bot do

  ### CONFIGURAÇÕES BÁSICAS ###
  @mensagem_post = "Quanto está custando <%quantidade%> BTC agora? Na Foxbit custa apenas R$<%preco%>! #bitcoin #foxbit"
  @mensagem_resposta = "Olá <%username%>, a cotação de <%quantidade%> BTC é R$<%preco%>. Você já conhece a Foxbit, a exchange mais adorada do Brasil?"
  @quantidade = 1

  ### CONFIGURAÇÕES AVANÇADAS ###
  @url_api = "https://quantocusta1bitcoin.herokuapp.com/api/v1/cotacao"
  cliente = Twitter::REST::Client.new do |config|
    config.consumer_key = ENV['CONSUMER_KEY']
    config.consumer_secret = ENV['CONSUMER_SECRET']
    config.access_token = ENV['ACCESS_TOKEN']
    config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
  end

  desc "TODO"
  task replies: :environment do

  end

  desc "Faz posts no Twitter do 'Quanto Custa 1 Bitcoin?' a cada 30 minutos."
  task post: :environment do

    # Verifica se a hora está em um intervalo de 30 minutos. Por exemplo, vai postar sempre em 15:00h e em 15:30h.
    loop do

      minute = Time.now.min
      if minute == 00 or minute == 30

        # Pega cotação na API do "Quanto Custa 1 Bitcoin?"
        cotacao_atual = checar_cotacao()

        # Formata mensagem com cotação atual
        mensagem_formatada = inserir_valores_post(cotacao_atual)

        # Envia mensagem para o Twitter
        cliente.update(mensagem_formatada)

        # Posta uma mensagem no terminal alertando sobre o post no Twitter.
        data = Time.now.strftime("%e %b %Y %H:%M:%S%p")
        Rails.logger.info("Postado no Twitter em #{data}: \"#{mensagem_formatada}\"")
      else
        data = Time.now.strftime("%H:%M:%S%p")
        Rails.logger.info("Não postado no Twitter. Hora atual: #{data}")
      end

      sleep 60

    end

  end

  # Checa a cotação do Bitcoin na Foxbit utilizando a API fornecida pelo "Quanto Custa 1 Bitcoin?". A cotação do preço do Bitcoin é baseada no Orderbook e na quantidade de Bitcoins requerida. O valor padrão para a quantidade de bitcoins é 1, mas isso é facilmente customizáve (já deixei preparado para tal mudança, caso seja necessária).
  def checar_cotacao(quantidade = @quantidade)

    # Acessando API do "Quanto Custa 1 Bitcoin?".
    response = HTTParty.post(@url_api, :query => { :amount => quantidade})

    # Requisição teve sucesso?
    if response.success?
      json = JSON.parse(response.body)

      # Checando se existe um valor não nulo para a chave "price" do JSON
      if json.has_key?("price")
        return json["price"]
      else
        raise "Chave ['price'] do JSON nula!"
      end
    else
      raise response.response
    end

  end

  # Método responsável por inserir os valores de preço e quantidade na "frase padrão" de post da cotação no Twitter.
  def inserir_valores_post(preco=nil, quantidade=1.0)
    mensagem = @mensagem_post.sub("<%quantidade%>", quantidade.to_s)
    mensagem = mensagem.sub("<%preco%>", preco.to_s)
    return mensagem
  end

  # Método responsável por inserir os valores de preço, quantidade e nome de usuário na "frase padrão" de responder pessoas no Twitter.
  def inserir_valores_resposta(preco=nil, username=nil, quantidade=1.0)
    mensagem = @mensagem_resposta.sub("<%quantidade%>", quantidade.to_s)
    mensagem = mensagem.sub("<%preco%>", preco.to_s)
    mensagem = mensagem.sub("<%username%>", username.to_s)
    return mensagem
  end

end


