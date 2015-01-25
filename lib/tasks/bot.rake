#encoding: utf-8
#
###
###   Arquivo responsável por inicializar as tarefas agendadas e recorrentes.
###
#
# Esse arquivo contém tarefas Rake, que são scripts de propósito específico e
# que neste caso servem para inicializar as tarefas agendadas e recorrentes
# desse bot. Em suma, o Bot rodará a cada X intervalo de tempo e é aqui que
# esta configuração pode ser modificada. Para executar essas tarefas Rake
# basta digitar o seguinte a partir do seu Terminal (na pasta raiz do projeto):
#
# => rake bot:start
#
#
# Esse comando fará com que as tarefas no Sidekiq (o responsável por agendar
# e organizar as tarefas) sejam criadas e rodem de acordo com os parâmetros
# escolhidos nas linhas abaixo. A única configuração mais difíl de entender é
# o "cron", que é basicamente um padrão que permite escrever intervalos de
# tempo. Existem diversos geradores de Cron na Internet, se precisar alterar
# os tempos de execução pode fazer manualmente ou através de um gerador como
# esse: http://www.crontab-generator.org/.
#
##
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
    reply_worker = Sidekiq::Cron::Job.new(name: 'Reply Worker - A cada min', cron: '* * * * *', klass: 'ReplyWorker', retry: 'false')
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

end
