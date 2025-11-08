# app/controllers/subscriptions_controller.rb
class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan, only: [ :new, :create ]

  def index
    @plans = Plan.active
    @plans_by_duration = @plans.group_by(&:duration_months)
    @user_subscription = current_user.active_subscription
  end

  def new
    @is_recurring = params[:recurring] == "false"

    if @is_recurring
      create_recurring_subscription
    else
      create_one_time_payment
    end
  end

  def create
    # This action might not be needed if we handle everything in new
    # But keeping it for form submissions if needed later
    @is_recurring = params[:recurring] == "false"

    if @is_recurring
      create_recurring_subscription
    else
      create_one_time_payment
    end
  end

  def success
    pending_data = session[:pending_payment]
    unless pending_data && params[:token]
      redirect_to subscriptions_path, alert: "No pending payment found."
      return
    end

    paypal_service = PaypalService.new
    begin
      response = paypal_service.capture_order(pending_data["paypal_order_id"])
      plan = Plan.find(pending_data["plan_id"])
      if response["status"] == "COMPLETED"
        subscription = current_user.subscriptions.create!(
          plan_id: pending_data["plan_id"],
          status: "active",
          current_period_start: Time.current,
          current_period_end: Time.current + plan.duration_months.months,
          auto_renew: false
        )
        current_user.payments.create!(
          plan: plan,
          subscription: subscription,
          amount: plan.price,
          paypal_payment_id: response["id"],
          paypal_order_id: pending_data[:paypal_order_id],
          status: "completed",
          payment_method: "paypal_one_time",
          payment_date: Time.current
        )
        flash[:success] = "Payment completed successfully!"
        session.delete(:pending_payment)
        redirect_to dashboard_index_path
      else
        flash[:alert] = "Failed to complete payment with PayPal. Status: #{response["status"]}"
        redirect_to subscriptions_path
      end
    rescue => e
      Rails.logger.error "Error completing one-time payment: #{e.message}"
      flash[:alert] = "Error completing payment: #{e.message}"
      redirect_to subscriptions_path
    end
  end

  def cancel
    session.delete(:pending_payment)
    flash[:notice] = "Payment was canceled."
    redirect_to subscriptions_path
  end

  def destroy
    @subscription = current_user.active_subscription

    if @subscription
      if @subscription.cancel!
        flash[:notice] = "Subscription canceled successfully."
      else
        flash[:alert] = "Failed to cancel subscription."
      end
    end

    redirect_to dashboard_index_path
  end

  private

  def set_plan
    @plan = Plan.find(params[:plan_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Plan not found."
    redirect_to subscriptions_path
  end

  def create_recurring_subscription
    unless paypal_configured?
      flash[:alert] = "PayPal is not configured. Please contact administrator."
      redirect_to subscriptions_path
      return
    end

    paypal_service = PaypalService.new
    return_url = success_subscriptions_url
    cancel_url = cancel_subscriptions_url

    if @plan.paypal_product_id.blank?
      begin
        paypal_product_id = paypal_service.create_product(
          name: @plan.name,
          description: @plan.description || @plan.name
        )
        @plan.update!(paypal_product_id: paypal_product_id)
      rescue => e
        Rails.logger.error "Failed to create PayPal product: #{e.message}"
        flash[:alert] = "Error creating PayPal product: #{e.message}"
        redirect_to subscriptions_path and return
      end
    end

    if @plan.paypal_plan_id.blank?
      begin
        paypal_plan_id = paypal_service.create_billing_plan(@plan)
        @plan.update!(paypal_plan_id: paypal_plan_id)
      rescue => e
        Rails.logger.error "Failed to create PayPal billing plan: #{e.message}"
        flash[:alert] = "Error creating PayPal billing plan: #{e.message}"
        redirect_to subscriptions_path and return
      end
    end

    begin
      Rails.logger.info "Creating PayPal subscription for plan: #{@plan.paypal_plan_id}"
      response = paypal_service.create_subscription(@plan, current_user, return_url, cancel_url)

      if response["status"] == "APPROVAL_PENDING" || response["status"] == "APPROVED"
        session[:pending_subscription] = {
          plan_id: @plan.id,
          paypal_subscription_id: response["id"]
        }

        approval_url = response["links"].find { |link| link["rel"] == "approve" }&.dig("href")

        if approval_url
          Rails.logger.info "Redirecting to PayPal approval URL"
          redirect_to approval_url, allow_other_host: true
        else
          Rails.logger.error "No approval URL found in PayPal response"
          flash[:alert] = "Failed to get approval URL from PayPal."
          redirect_to subscriptions_path
        end
      else
        Rails.logger.error "PayPal subscription creation failed: #{response}"
        flash[:alert] = "Failed to create subscription. Status: #{response['status']}"
        redirect_to subscriptions_path
      end
    rescue => e
      Rails.logger.error "Exception in create_recurring_subscription: #{e.message}\n#{e.backtrace.join("\n")}"
      flash[:alert] = "Error creating subscription: #{e.message}"
      redirect_to subscriptions_path
    end
  end

  def complete_recurring_subscription
    pending_data = session[:pending_subscription]
    return redirect_to subscriptions_path unless pending_data

    unless paypal_configured?
      flash[:alert] = "PayPal is not configured. Please contact administrator."
      redirect_to subscriptions_path
      return
    end

    paypal_service = PayPalService.new

    begin
      response = paypal_service.capture_subscription(pending_data[:paypal_subscription_id])

      if response["status"] == "ACTIVE"
        subscription = current_user.subscriptions.create!(
          plan_id: pending_data[:plan_id],
          paypal_subscription_id: pending_data[:paypal_subscription_id],
          status: "active",
          current_period_start: Time.current,
          current_period_end: Time.current + @plan.duration_months.months,
          paypal_payer_id: response.dig("subscriber", "payer_id")
        )

        current_user.payments.create!(
          plan: @plan,
          subscription: subscription,
          amount: @plan.price,
          paypal_payment_id: response["id"],
          status: "completed",
          payment_method: "paypal_recurring",
          payment_date: Time.current
        )

        flash[:success] = "Recurring subscription created successfully!"
        session.delete(:pending_subscription)
        redirect_to dashboard_index_path
      else
        flash[:alert] = "Failed to activate subscription. Status: #{response['status']}"
        redirect_to subscriptions_path
      end
    rescue => e
      Rails.logger.error "Error completing recurring subscription: #{e.message}"
      flash[:alert] = "Error completing subscription: #{e.message}"
      redirect_to subscriptions_path
    end
  end

  def create_one_time_payment
    session.delete(:pending_payment)
    unless session[:pending_payment]
      paypal_service = PaypalService.new
      return_url = success_subscriptions_url
      cancel_url = cancel_subscriptions_url

      response = paypal_service.create_order(@plan.price, return_url, cancel_url)
      if response["status"] == "CREATED"
        session[:pending_payment] = {
          plan_id: @plan.id,
          paypal_order_id: response["id"]
        }
        approval_url = response["links"].find { |link| link["rel"] == "approve" }&.dig("href")
        if approval_url
          redirect_to approval_url, allow_other_host: true and return
        end
      end
      flash[:alert] = "Failed to initiate PayPal payment"
      redirect_to subscriptions_path
    else
      # If already pending, either redirect back or clear session for user to retry
      flash[:alert] = "Payment already initiated, please complete or cancel before trying again."
      redirect_to subscriptions_path
    end
  end

  def complete_one_time_payment
    pending_data = session[:pending_payment]
    return redirect_to subscriptions_path unless pending_data

    unless paypal_configured?
      flash[:alert] = "PayPal is not configured. Please contact administrator."
      redirect_to subscriptions_path
      return
    end

    paypal_service = PaypalService.new

    begin
      response = paypal_service.capture_order(pending_data[:paypal_order_id])

      if response["status"] == "COMPLETED"
        subscription = current_user.subscriptions.create!(
          plan_id: pending_data[:plan_id],
          status: "active",
          current_period_start: Time.current,
          current_period_end: Time.current + @plan.duration_months.months,
          auto_renew: false
        )

        current_user.payments.create!(
          plan: @plan,
          subscription: subscription,
          amount: @plan.price,
          paypal_payment_id: response["id"],
          paypal_order_id: pending_data[:paypal_order_id],
          status: "completed",
          payment_method: "paypal_one_time",
          payment_date: Time.current
        )

        flash[:success] = "Payment completed successfully!"
        session.delete(:pending_payment)
        redirect_to dashboard_index_path
      else
        flash[:alert] = "Failed to complete payment with PayPal. Status: #{response["status"]}"
        redirect_to subscriptions_path
      end
    rescue => e
      Rails.logger.error "Error completing one-time payment: #{e.message}"
      flash[:alert] = "Error completing payment: #{e.message}"
      redirect_to subscriptions_path
    end
  end

  def paypal_configured?
    true
  end
end
