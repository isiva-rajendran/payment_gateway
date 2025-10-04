class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :subscriptions, dependent: :destroy
  has_many :payments, dependent: :destroy
  belongs_to :active_subscription, class_name: 'Subscription', optional: true

  # validates :first_name, presence: true
  # validates :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def has_active_subscription?
    active_subscription&.active?
  end

  def current_plan
    active_subscription&.plan
  end

  def trial_active?
    trial_ends_at.present? && trial_ends_at > Time.current
  end
end
