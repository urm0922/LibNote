# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Category.find_or_create_by(name: "貸出・返却")
Category.find_or_create_by(name: "利用カード")

[
  { email: "admin@example.com", name: "管理者", role: "admin" },
  { email: "manager@example.com", name: "マネージャー", role: "manager" }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(attrs)
  if user.new_record?
    user.password = "password"
    user.password_confirmation = "password"
  end
  user.save!
end