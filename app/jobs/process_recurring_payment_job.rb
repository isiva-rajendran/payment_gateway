class ProcessRecurringPaymentJob < ApplicationJob
  queue_as :default

  def perform(payment_id, subscription_id)
    payment = Payment.find(payment_id)
    subscription = Subscription.find(subscription_id)

    Rails.logger.info "Processing recurring payment #{payment_id} for subscription #{subscription_id}"

    begin
      # Process the payment through PayPal
      result = payment.process_payment!

      if payment.successful?
        # Extend subscription period on successful payment
        subscription.extend_period!
        Rails.logger.info "Successfully processed payment #{payment_id}"
      else
        # Handle failed payment
        payment.update!(status: 'failed')
        Rails.logger.error "Payment #{payment_id} failed"

        # You might want to notify the user or update subscription status
        # subscription.update!(status: 'past_due') if payment failures exceed threshold
      end
    rescue StandardError => e
      payment.update!(status: 'failed', notes: e.message)
      Rails.logger.error "Error processing payment #{payment_id}: #{e.message}"
      raise
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "ProcessRecurringPaymentJob: Record not found - #{e.message}"
  end
end
