# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# Variáveis globais interessantes
APP_VERSION = '1.0.0'
APP_NAME = Rails.application.config.session_options[:key].sub(/^_/,'').sub(/_session/,'')
