# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Delete existing plans
Plan.destroy_all

plans_data = [
  # Basic Plans
  { name: 'Basic 1 Month', duration_months: 1, plan_type: 'basic', price: 9.99 },
  { name: 'Basic 3 Months', duration_months: 3, plan_type: 'basic', price: 26.99 },
  { name: 'Basic 6 Months', duration_months: 6, plan_type: 'basic', price: 49.99 },
  { name: 'Basic 1 Year', duration_months: 12, plan_type: 'basic', price: 89.99 },
  
  # Advanced Plans
  { name: 'Advanced 1 Month', duration_months: 1, plan_type: 'advanced', price: 19.99 },
  { name: 'Advanced 3 Months', duration_months: 3, plan_type: 'advanced', price: 53.99 },
  { name: 'Advanced 6 Months', duration_months: 6, plan_type: 'advanced', price: 99.99 },
  { name: 'Advanced 1 Year', duration_months: 12, plan_type: 'advanced', price: 179.99 },
  
  # Premium Plans
  { name: 'Premium 1 Month', duration_months: 1, plan_type: 'premium', price: 29.99 },
  { name: 'Premium 3 Months', duration_months: 3, plan_type: 'premium', price: 80.99 },
  { name: 'Premium 6 Months', duration_months: 6, plan_type: 'premium', price: 149.99 },
  { name: 'Premium 1 Year', duration_months: 12, plan_type: 'premium', price: 269.99 }
]

plans_data.each do |plan_data|
  Plan.create!(plan_data)
  puts "Created plan: #{plan_data[:name]}"
end

puts "Created #{Plan.count} plans successfully!"

# Create admin user
puts "Creating admin user..."
User.create!(
  email: 'admin@example.com',
  password: '123456',
  password_confirmation: '123456',
  first_name: 'Admin',
  last_name: 'User',
  admin: true,
)

puts "Admin user created: admin@paymentapp.com / password123"