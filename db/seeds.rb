# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Starter users for development/testing. Add real users via the Rails console:
#   User.create!(email: "person@boardpackager.com", password: "a-good-password")
#   User.create!(email: "boss@boardpackager.com", password: "...", admin: true)
if Rails.env.local?
  User.find_or_create_by!(email: "demo@boardpackager.com") do |user|
    user.password = "password"
  end
  User.find_or_create_by!(email: "admin@boardpackager.com") do |user|
    user.password = "password"
    user.admin = true
  end
end
