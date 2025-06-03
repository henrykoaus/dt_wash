class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  enum :role, [ :customer, :merchant ]
  after_create :create

  has_one :profile
  accepts_nested_attributes_for :profile
  has_many :orders_as_customer, class_name: 'Order', foreign_key: 'customer_id'
  has_many :orders_as_merchant, class_name: 'Order', foreign_key: 'merchant_id'
  private
  def create
    Profile.create(user: self)
  end
end
