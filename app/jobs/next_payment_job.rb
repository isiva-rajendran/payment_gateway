class NextPaymentJob < ApplicationJob
  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find(subscription_id)

    # Check if subscription is still active and should renew
    return unless subscription.active? && subscription.auto_renew?

    Rails.logger.info "Processing scheduled payment for subscription #{subscription_id}"

    # Trigger the renewal process
    subscription.renew!
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "NextPaymentJob: Subscription #{subscription_id} not found"
  rescue StandardError => e
    Rails.logger.error "NextPaymentJob failed for subscription #{subscription_id}: #{e.message}"
    raise # Re-raise to allow job retry mechanisms to work
  end
end
