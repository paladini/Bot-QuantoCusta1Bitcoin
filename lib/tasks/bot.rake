# #encoding: utf-8

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

end
