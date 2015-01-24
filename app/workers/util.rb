#encoding: utf-8
require 'twitter'
require 'httparty'
require 'json'

module Util

  ### CONFIGURAÇÕES BÁSICAS ###
  @mensagem_post = "Quanto está custando <%quantidade%> BTC agora? Na Foxbit custa apenas R$<%preco%>! #bitcoin #foxbit"
  @mensagem_resposta = "Olá @<%username%>, a cotação de <%quantidade%> BTC na #Foxbit é de R$<%preco%>. Aproveite a promoção de taxa 0 e negocie bitcoins na @foxbitcoin"
  @quantidade = 1.0
  @participar_de_conversas = false

  ### CONFIGURAÇÕES AVANÇADAS ###
  @url_api = "http://www.quantocusta1bitcoin.com.br/api/v1/cotacao"
  @consumer_key = ENV['CONSUMER_KEY']
  @consumer_secret = ENV['CONSUMER_SECRET']
  @access_token = ENV['ACCESS_TOKEN']
  @access_token_secret = ENV['ACCESS_TOKEN_SECRET']


  # Checa a cotação do Bitcoin na Foxbit utilizando a API fornecida pelo "Quanto Custa 1 Bitcoin?". A cotação do preço do Bitcoin é baseada no Orderbook e na quantidade de Bitcoins requerida. O valor padrão para a quantidade de bitcoins é 1, mas isso é facilmente customizáve (já deixei preparado para tal mudança, caso seja necessária).
  def self.checar_cotacao(quantidade = @quantidade)

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
  def self.inserir_valores_post(preco=nil, quantidade=@quantidade)
    mensagem = @mensagem_post.sub("<%quantidade%>", quantidade.to_s)
    mensagem = mensagem.sub("<%preco%>", preco.to_s)
    return mensagem
  end

  # Método responsável por inserir os valores de preço, quantidade e nome de usuário na "frase padrão" de responder pessoas no Twitter.
  def self.inserir_valores_resposta(preco=nil, username=nil, quantidade=@quantidade)
    mensagem = @mensagem_resposta.sub("<%quantidade%>", quantidade.to_s)
    mensagem = mensagem.sub("<%preco%>", preco.to_s)
    mensagem = mensagem.sub("<%username%>", username.to_s)
    return mensagem
  end

  # Salvando data da última resposta em um arquivo .json.
  def self.salvar_data(data = Time.now )
    json = {
      :lastAnsweredTweet => data
    }
    File.open("public/answers.json","w") do |f|
      f.write(json.to_json)
    end
  end

  # Lendo a data do último tweet respondido.
  # Caso o arquivo não exista, retorna uma data de 42 anos atrás. Não tem nada de especial na data, ela apenas tinha que ser uma data qualquer antes da criação do perfil do bot (para garantir que nenhum tweet antigo fique sem resposta por supostamente já ter sido respondido).
  def self.ler_data()
    begin
      data = JSON.parse(File.read(Rails.public_path.join('answers.json')))
      data = DateTime.parse(data["lastAnsweredTweet"])
    rescue Errno::ENOENT => e
      data = nil
      Rails.logger.error("============================================")
      Rails.logger.error("[ERRO] Erro que pode ser não fatal caso esteja ocorrendo na primeira vez. \nCaso este seja um erro recorrente, entre em contato com o administrador do sistema. \nMensagem de erro: " + e.message)
      Rails.logger.error("============================================")

    ensure
      return data || 42.years.ago
    end
  end

  #### Variáveis de classe (getters e setters) ####
  def self.cliente
    return Twitter::REST::Client.new do |config|
      config.consumer_key = @consumer_key
      config.consumer_secret = @consumer_secret
      config.access_token = @access_token
      config.access_token_secret = @access_token_secret
    end
  end

  def self.participar_de_conversas
    return @participar_de_conversas
  end

end
