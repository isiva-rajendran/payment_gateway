# app/services/paypal_service.rb
require 'net/http'
require 'uri'
require 'json'

class PaypalService
  class PayPalError < StandardError; end

  def initialize
    @base_url = 'sandbox' == 'live' ? 
      'https://api.paypal.com' : 
      'https://api.sandbox.paypal.com'
    @access_token = get_access_token
  end

  # Create a one-time payment order
  def create_order(amount, return_url, cancel_url)
    uri = URI.parse("#{@base_url}/v2/checkout/orders")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@access_token}"
    request['Prefer'] = 'return=representation'

    request_body = {
      intent: 'CAPTURE',
      purchase_units: [{
        amount: { currency_code: 'USD', value: '%.2f' % amount }
      }],
      application_context: {
        return_url: return_url,
        cancel_url: cancel_url,
        user_action: 'PAY_NOW',
        shipping_preference: 'NO_SHIPPING'
      }
    }
    request.body = request_body.to_json
    Rails.logger.info("Creating PayPal order with: #{request_body}")
    response = http.request(request)
    handle_response(response)
  end

  def capture_order(order_id)
    p "22222222222"
    p "Capturing order #{order_id}"
    uri = URI.parse("#{@base_url}/v2/checkout/orders/#{order_id}/capture")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri) # CRITICAL FIX!
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@access_token}"
    request['Prefer'] = 'return=representation'

    response = http.request(request)
    handle_response(response)
  end

  # Create a recurring subscription
  def create_subscription(plan, user, return_url, cancel_url)
    raise PayPalError, "Plan missing PayPal plan ID" unless plan.paypal_plan_id.present?

    uri = URI.parse("#{@base_url}/v1/billing/subscriptions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@access_token}"
    request['Prefer'] = 'return=representation'

    request_body = {
      plan_id: plan.paypal_plan_id,
      subscriber: {
        name: {
          given_name: user.first_name || user.email.split('@').first,
          surname: user.last_name || "User"
        },
        email_address: user.email
      },
      application_context: {
        brand_name: 'My Payment Gateway Test' || 'Payment App',
        locale: 'en-US',
        shipping_preference: 'NO_SHIPPING',
        user_action: 'SUBSCRIBE_NOW',
        return_url: return_url,
        cancel_url: cancel_url
      }
    }

    request.body = request_body.to_json
    
    Rails.logger.info "Creating PayPal subscription with: #{request_body}"
    response = http.request(request)
    handle_response(response)
  end

  # Get subscription details
  def capture_subscription(subscription_id)
    uri = URI.parse("#{@base_url}/v1/billing/subscriptions/#{subscription_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@access_token}"

    response = http.request(request)
    handle_response(response)
  end

  private

  def get_access_token
    uri = URI.parse("#{@base_url}/v1/oauth2/token")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['Accept'] = 'application/json'
    request['Accept-Language'] = 'en_US'

    # Use environment variables instead of hardcoded credentials
    client_id = 'AeElQocmXzCtRk5Q-63jbso513IT5cziGiHzYT0JTA16mEOsYbtbiwlREDyEFKXGiMPCTTB0LSUMs5nw' || 'AeElQocmXzCtRk5Q-63jbso513IT5cziGiHzYT0JTA16mEOsYbtbiwlREDyEFKXGiMPCTTB0LSUMs5nw'
    client_secret = 'EIPJeijqFo1RQFcsjx5FNx0EGQ2Rx-gQZ78yiXzcDXPxGRmT4jphs91CjRoW5sTqZ1BXDgWxmISSjadn' || 'EIPJeijqFo1RQFcsjx5FNx0EGQ2Rx-gQZ78yiXzcDXPxGRmT4jphs91CjRoW5sTqZ1BXDgWxmISSjadn'

    request.basic_auth(client_id, client_secret)
    request.set_form_data({ 'grant_type' => 'client_credentials' })

    response = http.request(request)

    if response.code != '200'
      Rails.logger.error "PayPal Auth Failed: #{response.body}"
      raise PayPalError, "Failed to get access token: #{response.body}"
    end

    result = JSON.parse(response.body)
    result['access_token']
  end

  def handle_response(response)
    Rails.logger.info "PayPal Response: #{response.code} - #{response.body}"

    result = JSON.parse(response.body) rescue { 'error' => 'Invalid JSON response' }

    case response
    when Net::HTTPSuccess
      result
    else
      error_message = result['message'] || result['error'] || result['details']&.first&.dig('description') || 'Unknown PayPal error'
      Rails.logger.error "PayPal API Error: #{error_message} (Status: #{response.code})"
      raise PayPalError, "PayPal API Error: #{error_message} (Status: #{response.code})"
    end
  end
end
