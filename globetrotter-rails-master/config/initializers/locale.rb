# frozen_string_literal: true

# Where the I18n library should search for translation files
I18n.load_path += Dir[Rails.root.join('config', 'locale', '*.yml')]

# Permitted locales available for the application
I18n.available_locales = %i[en fr]
