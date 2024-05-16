Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'pages#home'
  get 'about', to: 'pages#about'
  get 'contact', to: 'pages#contact'
  get 'entreprises', to: 'pages#entreprises'
  get 'particuliers', to: 'pages#particuliers'
  get 'nos_services', to: 'pages#nos_services'
  get 'recrutement', to: 'pages#recrutement'
end
