module SubscriptionsHelper
  def calculate_discount_percentage(duration)
    case duration
    when 1 then 0
    when 3 then 10
    when 6 then 20
    when 12 then 25
    else 0
    end
  end

  def plan_description(plan_type)
    case plan_type
    when 'basic'
      "Perfect for individuals getting started"
    when 'advanced'
      "Best for growing teams and businesses"
    when 'premium'
      "For large organizations and enterprises"
    else
      "Perfect for your needs"
    end
  end

  def plan_features(plan_type)
    case plan_type
    when 'basic'
      [
        "5 Projects",
        "10 GB Storage", 
        "Email Support",
        "Basic Analytics"
      ]
    when 'advanced'
      [
        "Unlimited Projects",
        "100 GB Storage",
        "Priority Support 24/7", 
        "Advanced Analytics",
        "Team Collaboration",
        "API Access"
      ]
    when 'premium'
      [
        "Everything in Advanced",
        "Unlimited Storage", 
        "Dedicated Account Manager",
        "Custom Integrations",
        "Advanced Security", 
        "SLA Guarantee"
      ]
    else
      ["Standard features", "Basic support"]
    end
  end
end
