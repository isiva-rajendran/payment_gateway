class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan
  has_many :payments, dependent: :nullify

  # Constants
  STATUSES = ['active', 'canceled', 'past_due', 'expired', 'pending', 'trialing']
  validates :status, inclusion: { in: STATUSES }

  # Validations
  validates :current_period_start, presence: true
  validates :current_period_end, presence: true

  # Callbacks
  after_create :set_user_active_subscription
  after_save :update_user_subscription_status
  after_commit :schedule_next_payment, on: :create, if: :recurring?

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :expired, -> { where('current_period_end < ?', Time.current) }
  scope :needing_renewal, -> { active.where('current_period_end < ?', 1.day.from_now) }

  # Instance Methods
  def active?
    status == 'active' && current_period_end > Time.current
  end

  def recurring?
    paypal_subscription_id.present? && auto_renew
  end

  def expired?
    current_period_end < Time.current
  end

  def cancel!
    update!(
      status: 'canceled',
      canceled_at: Time.current,
      auto_renew: false
    )
  end

  def renew!
    return unless recurring? && auto_renew?

    # Create payment record for renewal
    payment = user.payments.create!(
      plan: plan,
      subscription: self,
      amount: plan.price,
      payment_method: 'paypal_recurring',
      payment_date: Time.current,
      status: 'pending'
    )

    # Process the renewal payment
    ProcessRecurringPaymentJob.perform_later(payment.id, id)
  end

  def schedule_next_payment
    return unless recurring? && auto_renew?

    # Schedule payment for 1 day before expiration to ensure continuity
    NextPaymentJob.set(wait_until: current_period_end - 1.day).perform_later(id)
  end

  def extend_period!
    update!(
      current_period_start: Time.current,
      current_period_end: Time.current + plan.duration_months.months
    )
  end

  private

  def set_user_active_subscription
    user.update!(active_subscription: self) if active?
  end

  def update_user_subscription_status
    user.update!(subscription_status: status)
  end

  def auto_renew?
    auto_renew && status == 'active'
  end
end
