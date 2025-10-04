class Plan < ApplicationRecord
  # Constants
  PLAN_TYPES = ['basic', 'advanced', 'premium']
  DURATIONS = [1, 3, 6, 12]
  BILLING_CYCLE_TYPES = ['monthly', 'quarterly', 'semi-annual', 'annual']

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :duration_months, presence: true, inclusion: { in: DURATIONS }
  validates :plan_type, presence: true, inclusion: { in: PLAN_TYPES }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :billing_cycle_type, inclusion: { in: BILLING_CYCLE_TYPES }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_duration, ->(months) { where(duration_months: months) }
  scope :by_type, ->(type) { where(plan_type: type) }
  scope :basic, -> { where(plan_type: 'basic') }
  scope :advanced, -> { where(plan_type: 'advanced') }
  scope :premium, -> { where(plan_type: 'premium') }

  # Instance Methods
  def display_name
    "#{plan_type.capitalize} - #{duration_months} #{duration_months == 1 ? 'Month' : 'Months'}"
  end

  def monthly_price
    price / duration_months
  end

  def recurring?
    true # All plans support recurring payments
  end

  def create_paypal_plan
    PayPalService.new.create_billing_plan(self)
  end
end
