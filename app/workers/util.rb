#encoding: utf-8
#
###
### Responsável por boa parte das configurações do projeto.
###
#
# Esse arquivo é responsável por boa parte das configurações desse projeto e
# também é responsável por vários métodos úteis ao projeto. Abaixo uma
# explicação mais detalhada das configurações.
#
# [OBS] Não alterar as tags <% ... %>, pode fazer com que o programa não
#       funcione de maneira correta. Pode mudar as tags de lugar na frase,
#       mas não deve ser excluído ou ter o seu conteúdo interno modificado.
#
# ===== BÁSICAS =====
#
#  @mensagem_post:
#      A mensagem que será enviada pelo Bot ao Twitter informando a cotação
#      do Bitcoin na Foxbit a cada X minutos (padrão=30 minutos).
#
#  @mensagem_resposta:
#      A mensagem que será enviada pelo Bot ao Twitter respondendo às menções
#      de outros usuários informando a cotação do Bitcoin na Foxbit.
#
#  @quantidade:
#      A quantidade de bitcoins para qual será retornada a cotação (tanto no
#      post como nas respostas). O padrão é 1.0 BTC. Tomar cuidado para não
#      aumentar a ponto de ultrapassar a quantidade de BTC's disponível à
#      venda na Foxbit.
#
#  @participar_de_conversas:
#      Opção que determina se o Bot responderá SEMPRE que for citado,
#      incluindo conversas no Twitter. Pelos testes que fiz e os cenários que
#      imaginei ativar essa opção é algo ruim, mas deixei como uma opção para
#      aumentar o nível de personalização do sistema. Cenários possíveis:
#            a. Alguém pede cotação, Bot responde, pessoa agradece, Bot
#               responde a mesma coisa - denovo, e assim por diante.
#            b. Alguém marca Bot em uma conversa aleatória, ele vai responder
#               em um lugar que pode ficar totalmente fora de contexot.
#            c. Várias pessoas respondem um post do Bot, para cada nova
#               resposta o Bot vai postar a cotação do Btc.
#            d. Há muitos outros cenários negativos.

#      A configuração padrão é FALSE - pensar seriamente nas implicações de
#      interação GIGANTES caso pensem em ativar essa opção.
#
#
# ===== AVANÇADAS =====
#
#  @url_api:
#      A URL da API do projeto "Quanto Custa 1 Bitcoin?". Não é necessário
#      modificar a menos que o projeto tenha seu domínio modificado ou algum
#      problema do tipo aconteça.
#
#  @consumer_key:
#      Chave necessária e obtida através do apps.twitter.com.
#
#  @consumer_secret:
#      Chave necessária e obtida através do apps.twitter.com.
#
#  @access_token:
#      Chave necessária e obtida através do apps.twitter.com.
#
#  @access_token_secret:
#      Chave necessária e obtida através do apps.twitter.com.
#
#
# Sobre as variáveis de ambiente:
#     As variáveis de ambiente (ENV['CONSUMER_KEY'], por exemplo) são variáveis
#     famosas em qualquer sistema Unix e mais populares ainda em
#     desenvolvimento de projetos. Todas essas variáveis de ambiente do código #     estão configuradas e disponíveis no Heroku, assim como no localhost
#     através do arquivo ".env" e da gem "dotenv-rails". Isso permite que
#     tanto o sistema de Produção como o sistema de desenvolvimento tenham
#     acesso às mesmas chaves de forma mais ou menos segura do que estarem
#     "hardcoded".
#
##
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
  @url_api = "http://quantocusta1bitcoin.herokuapp.com/api/v1/cotacao"
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
      Rails.logger.error("Erro no HTTParty: #{response}")
      raise "Error: #{response.response}"
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
