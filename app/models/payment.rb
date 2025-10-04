class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :plan
  belongs_to :subscription, optional: true

  # Constants
  STATUSES = ['completed', 'pending', 'failed', 'refunded', 'canceled']
  PAYMENT_METHODS = ['paypal_one_time', 'paypal_recurring', 'paypal_recurring_auto', 'card']

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :payment_date, presence: true

  # Callbacks
  before_create :generate_invoice_id

  # Scopes
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(payment_date: :desc) }

  # Instance Methods
  def successful?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def process_payment!
    return if successful?

    case payment_method
    when 'paypal_one_time'
      PayPalService.new.capture_payment(paypal_order_id)
    when 'paypal_recurring'
      PayPalService.new.process_recurring_payment(subscription.paypal_subscription_id, amount)
    end
  end

  private

  def generate_invoice_id
    self.invoice_id ||= "INV-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end
end
