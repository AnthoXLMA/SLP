class Payment < NonPersistent
  column :amount, :float
  column :ewallet_amount, :float
  column :currency, :string
  column :payment_type, :string, default: 'mangopay_cards'

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 2 }
  validates :ewallet_amount, numericality: { greater_than_or_equal_to: :amount }, if: :ewallet_amount
  validates :currency, presence: true
  validates :payment_type, presence: true
end
