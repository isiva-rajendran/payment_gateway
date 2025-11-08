# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def paypal
    event_type = params[:event_type]
    resource   = params[:resource]

    Rails.logger.info "PayPal Webhook Received: #{event_type}, resource: #{resource}"

    case event_type
    # Recurring subscriptions
    when 'BILLING.SUBSCRIPTION.ACTIVATED'
      handle_subscription_activated(resource)
    when 'BILLING.SUBSCRIPTION.CANCELLED'
      handle_subscription_cancelled(resource)
    when 'BILLING.SUBSCRIPTION.EXPIRED'
      handle_subscription_expired(resource)
    when 'BILLING.SUBSCRIPTION.SUSPENDED'
      handle_subscription_suspended(resource)
    when 'PAYMENT.SALE.COMPLETED'
      handle_recurring_payment_completed(resource)
    when 'BILLING.SUBSCRIPTION.PAYMENT.FAILED'
      handle_payment_failed(resource)

    # One-time payments
    when 'CHECKOUT.ORDER.APPROVED', 'PAYMENT.CAPTURE.COMPLETED'
      handle_one_time_payment_completed(resource)

    else
      Rails.logger.info "Unhandled PayPal webhook event: #{event_type}"
    end

    head :ok
  rescue => e
    Rails.logger.error "Error processing PayPal webhook: #{e.message}\n#{e.backtrace.join("\n")}"
    head :unprocessable_entity
  end

  private

  # -----------------------------
  # Recurring Subscriptions
  # -----------------------------

  def handle_subscription_activated(resource)
    subscription = Subscription.find_or_initialize_by(paypal_subscription_id: resource["id"])
    subscription.user ||= User.find_by(email: resource.dig("subscriber","email_address"))
    subscription.plan ||= Plan.find_by(paypal_plan_id: resource["plan_id"])

    subscription.status = 'active'
    subscription.current_period_start = Time.parse(resource.dig("billing_info","last_payment","time") || Time.current.to_s)
    subscription.current_period_end   = Time.parse(resource.dig("billing_info","next_billing_time") || (Time.current + subscription.plan.duration_months.months).to_s)
    subscription.save!

    Rails.logger.info "Subscription activated: #{resource['id']}"
  end

  def handle_recurring_payment_completed(resource)
    subscription = Subscription.find_by(paypal_subscription_id: resource["billing_agreement_id"])
    return unless subscription

    return if Payment.exists?(paypal_payment_id: resource["id"])

    payment = subscription.user.payments.create!(
      plan: subscription.plan,
      subscription: subscription,
      amount: resource.dig("amount","value").to_f,
      paypal_payment_id: resource["id"],
      status: 'completed',
      payment_method: 'paypal_recurring_auto',
      auto_renew: true,
      payment_date: Time.parse(resource["create_time"])
    )

    subscription.update!(
      current_period_start: Time.current,
      current_period_end: Time.current + subscription.plan.duration_months.months,
      status: 'active'
    )

    Rails.logger.info "Recurring payment completed: #{resource['id']}"
  end

  def handle_payment_failed(resource)
    subscription = Subscription.find_by(paypal_subscription_id: resource["id"])
    return unless subscription

    subscription.update!(
      status: 'past_due',
      retry_count: subscription.retry_count + 1,
      next_payment_attempt: 3.days.from_now
    )

    payment = subscription.user.payments.create!(
      plan: subscription.plan,
      subscription: subscription,
      amount: subscription.plan.price,
      status: 'failed',
      payment_method: 'paypal_recurring_auto',
      payment_date: Time.current,
      notes: "Automatic payment failed: #{resource.dig('billing_info','outstanding_balance','value')}"
    )

    if subscription.retry_count < 3
      RetryPaymentJob.set(wait_until: subscription.next_payment_attempt).perform_later(payment.id, subscription.id)
    else
      subscription.cancel!
      UserMailer.subscription_canceled_due_to_failures(subscription.user, subscription).deliver_later
    end

    UserMailer.payment_failed(subscription.user, payment, "Automatic payment failed").deliver_later

    Rails.logger.info "Payment failed for subscription: #{subscription.paypal_subscription_id}"
  end

  def handle_subscription_cancelled(resource)
    subscription = Subscription.find_by(paypal_subscription_id: resource["id"])
    return unless subscription

    subscription.cancel!
    UserMailer.subscription_canceled(subscription.user, subscription).deliver_later

    Rails.logger.info "Subscription canceled: #{resource['id']}"
  end

  def handle_subscription_expired(resource)
    subscription = Subscription.find_by(paypal_subscription_id: resource["id"])
    return unless subscription

    subscription.update!(status: 'expired')
    UserMailer.subscription_expired(subscription.user, subscription).deliver_later

    Rails.logger.info "Subscription expired: #{resource['id']}"
  end

  def handle_subscription_suspended(resource)
    subscription = Subscription.find_by(paypal_subscription_id: resource["id"])
    return unless subscription

    subscription.update!(status: 'past_due')
    UserMailer.subscription_suspended(subscription.user, subscription).deliver_later

    Rails.logger.info "Subscription suspended: #{resource['id']}"
  end

  # -----------------------------
  # One-time Payments
  # -----------------------------

  def handle_one_time_payment_completed(resource)
    order_id = resource["id"]
    payer_email = resource.dig("payer","email_address")
    user = User.find_by(email: payer_email)
    return unless user

    # Check if already processed
    return if Payment.exists?(paypal_payment_id: order_id)

    plan_price = resource.dig("purchase_units",0,"amount","value").to_f
    plan = Plan.find_by(price: plan_price)

    subscription = Subscription.create!(
      user: user,
      plan: plan,
      status: 'active',
      current_period_start: Time.current,
      current_period_end: Time.current + 1.month,
      auto_renew: false
    )

    subscription.user.payments.create!(
      plan: plan,
      subscription: subscription,
      amount: plan_price,
      paypal_payment_id: order_id,
      paypal_order_id: order_id,
      status: 'completed',
      payment_method: 'paypal_one_time',
      payment_date: Time.current
    )

    Rails.logger.info "One-time payment completed: #{order_id}"
  end
end
