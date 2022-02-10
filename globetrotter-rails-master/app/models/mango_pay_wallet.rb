MangoPay.configure do |c|
  c.preproduction = true
  c.client_id = 'theglobetrottest'
  c.client_apiKey = 'vRVTrx5Q7Rb952gRMZNcQyFcg1vOm9Pazyj59VGYrzpO6UWsKL'
  # c.log_file = File.join('mypath', 'mangopay.log')
  c.http_timeout = 10_000
end

PERCENTAGE_FEE = 0.1

class MangoPayWallet
  attr_reader :mangopay_user_id, :mangopay_wallet

  def self.getOrCreate(user, currency)
    if user.mangopay_user_id
      Rails.logger.debug 'Mango User id for ' + user.id.to_s + ' already exists'
      wallets = MangoPay::User.wallets(user.mangopay_user_id)
      currency_wallets = wallets.select { |w| w['Currency'] == currency }
      if currency_wallets.length > 0
        MangoPayWallet.new(user.mangopay_user_id, wallets[0])
      else
        Rails.logger.debug 'Wallet for ' + currency + ' does not exist, creating...'
        createWallet(user.mangopay_user_id, currency)
      end
    else
      Rails.logger.debug 'Mango User id for ' + user.id.to_s + ' does not exist'
      begin
        mango_user = MangoPay::NaturalUser.create({
                                                    'Email' => user.email,
                                                    'FirstName' => user.firstname,
                                                    'LastName' => user.lastname,
                                                    'Birthday' => user.birthdate_unix,
                                                    'Nationality' => user.nationality,
                                                    'CountryOfResidence' => user.country
                                                  })
        user.mangopay_user_id = mango_user['Id']
        user.save
        createWallet(user.mangopay_user_id, currency)
      rescue MangoPay::ResponseError => e
        Rails.logger.debug e
      end
    end
  end

  def self.createWallet(user_id, currency)
    wallet = MangoPay::Wallet.create({
                                       'Owners' => [user_id],
                                       'Description' => 'GT-' + currency,
                                       'Currency' => currency
                                     })
    MangoPayWallet.new(user_id, wallet)
  rescue MangoPay::ResponseError => e
    Rails.logger.debug e
  end

  def self.requestPaymentUrl(user, guide_wallet, user_wallet, payment, after_pay_return_url)
    MangoPay::PayIn::Card::Web.create({
                                        'AuthorId' => user_wallet.mangopay_user_id,
                                        'CreditedUserId' => payment.payment_type === 'mangopay_ewallet' ? user_wallet.mangopay_user_id : guide_wallet.mangopay_user_id,
                                        'DebitedFunds' => {
                                          'Amount' => payment.payment_type === 'mangopay_ewallet' ? (payment.ewallet_amount * 100).round : (payment.amount * 100).round,
                                          'Currency' => user_wallet.mangopay_wallet['Currency']
                                        },
                                        'Fees' => {
                                          'Amount' => payment.payment_type === 'mangopay_ewallet' ? 0 : (payment.amount * PERCENTAGE_FEE * 100).round,
                                          'Currency' => user_wallet.mangopay_wallet['Currency']
                                        },
                                        'ReturnURL' => payment.payment_type === 'mangopay_ewallet' ? after_pay_return_url + '?tip=' + payment.amount.to_s : after_pay_return_url,
                                        'CardType' => 'CB_VISA_MASTERCARD',
                                        'CreditedWalletId' => payment.payment_type === 'mangopay_ewallet' ? user_wallet.mangopay_wallet['Id'] : guide_wallet.mangopay_wallet['Id'],
                                        'Culture' => user.language.upcase
                                      })
  rescue MangoPay::ResponseError => e
    Rails.logger.debug e
  end

  def self.walletTransfer(guide_wallet, user_wallet, amount)
    MangoPay::Transfer.create({
                                'AuthorId' => user_wallet.mangopay_user_id,
                                'CreditedUserId' => guide_wallet.mangopay_user_id,
                                'DebitedFunds' => {
                                  'Amount' => (amount * 100).round,
                                  'Currency' => user_wallet.mangopay_wallet['Currency']
                                },
                                'Fees' => {
                                  'Amount' => (amount * PERCENTAGE_FEE * 100).round,
                                  'Currency' => user_wallet.mangopay_wallet['Currency']
                                },
                                'DebitedWalletId' => user_wallet.mangopay_wallet['Id'],
                                'CreditedWalletId' => guide_wallet.mangopay_wallet['Id']
                              })
  rescue MangoPay::ResponseError => e
    Rails.logger.debug e
  end

  def self.getTransaction(user, transaction_id)
    transactions = MangoPay::User.transactions(user.mangopay_user_id,
                                               { 'sort' => 'CreationDate:desc', 'per_page' => 100 })
    transactions.detect { |t| t['Id'] == transaction_id }
  rescue MangoPay::ResponseError => e
    Rails.logger.debug e
  end

  def initialize(mangopay_user_id, mangopay_wallet)
    @mangopay_user_id = mangopay_user_id
    @mangopay_wallet = mangopay_wallet
  end
end
