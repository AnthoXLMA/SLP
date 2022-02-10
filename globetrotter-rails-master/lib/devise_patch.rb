require 'devise'
require 'devise/version'

raise unless Devise::VERSION === '4.8.1'

module Devise
  module Mailers
    module Helpers
      # Configure default email options
      def devise_mail(record, action, opts = {}, &block)
        initialize_from_record(record)
        I18n.with_locale(record.language || 'en') do
          mail headers_for(action, opts), &block
        end
      end
    end
  end
end

# https://github.com/heartcombo/devise/issues/5463
module ActionDispatch::Routing
  class Mapper
    def devise_registration(mapping, controllers) #:nodoc:
      path_names = {
        new: mapping.path_names[:sign_up],
        edit: mapping.path_names[:edit],
        cancel: mapping.path_names[:cancel]
      }

      options = {
        only: [:edit, :update, :destroy],
        path: mapping.path_names[:registration],
        path_names: path_names,
        controller: controllers[:registrations]
      }

      # force :create to be at same url than :new
      resource :registration, options do
        get :new, path: mapping.path_names[:sign_up], as: 'new'
        post :create, path: mapping.path_names[:sign_up], as: 'create'
        get :cancel
      end
    end
  end
end

