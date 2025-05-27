# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

import "faker"
require 'net/http'
require 'json'
require 'date'

Order.destroy_all
Profile.destroy_all
User.destroy_all

# add Users
paul = User.new
paul.username = "paul"
paul.email = "paul618300@gmail.com"
paul.password = "123456"
paul.role = 0
paul.profile = Profile.new
paul.save

henry = User.new
henry.username = "henry"
henry.email = "butwoo91@gmail.com"
henry.password = "123456"
henry.role = 1
henry.profile = Profile.new
henry.save

# add orders
30.times do
  order = Order.new
  order.status = (0..5).to_a.sample
  order.address = Faker::Address.full_address
  order.notes = Faker::Lorem.paragraph(sentence_count: 3, supplemental: true)
  order.price = (50..100).to_a.sample.to_f
  order.customer = User.all.first
  order.merchant = User.all.last
  order.save
end
