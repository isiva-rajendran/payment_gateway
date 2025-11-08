class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user_subscription = current_user.active_subscription
    @recent_payments = current_user.payments.completed.recent.limit(5)
    @active_plan = @user_subscription&.plan
  end

  def payment_history
    # @payments = current_user.payments.recent.page(params[:page]).per(10)
  end

  def subscription_details
    @subscription = current_user.active_subscription
    if @subscription.nil?
      flash[:alert] = 'No active subscription found.'
      redirect_to dashboard_index_path
    end
  end
end