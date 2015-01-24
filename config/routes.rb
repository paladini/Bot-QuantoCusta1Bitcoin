Rails.application.routes.draw do

  # Monitoramento das tarefas agendadas.
  # Para verificar a execução de tarefas, vá em: www.meusite.com/sidekiq/.
  # Login e senha podem ser encontrados nas variáveis de ambiente SIDEKIQ_USERNAME e SIDEKIQ_PASSWORD dentro do arquivo ".env".
  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV["SIDEKIQ_USERNAME"] && password == ENV["SIDEKIQ_PASSWORD"]
  end if Rails.env.production?
  mount Sidekiq::Web, at: "/sidekiq"

end
