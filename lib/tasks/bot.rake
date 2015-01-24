#encoding: utf-8
namespace :bot do

  desc "Tarefa responsável por iniciar os bots do sistema."
  task start: :environment do

    # Criando tarefa agendada para realizar Posts no Twitter.
    hardWorker = Sidekiq::Cron::Job.new(name: 'Hard worker - every 30min', cron: '*/30 * * * *', klass: 'HardWorker', retry: 'true')
    if hardWorker.save
        puts "==============================================="
        puts " CronJob \"PostWorker\" criado com sucesso."
        puts "==============================================="
    else
        puts "====================="
        puts hardWorker.errors
        puts "====================="
    end
    hardWorker.enque!

    # Criando tarefa agendada para responder tweets (replies).
    # replyWorker = Sidekiq::Cron::Job.create(name: 'Reply worker - every min', cron: '*/30 * * * *', klass: 'ReplyWorker')
    # if replyWorker.save
    #     puts "==============================================="
    #     puts " CronJob \"ReplyWorker\" criado com sucesso."
    #     puts "==============================================="
    # else
    #     puts "====================="
    #     puts replyWorker.errors
    #     puts "====================="
    # end
    # replyWorker.enque!

  end

end
