class Order < ApplicationRecord
  attr_accessor :distance

  belongs_to :customer, class_name: 'User'
  belongs_to :merchant, class_name: 'User', optional: true
  has_many :clothings, dependent: :destroy
  accepts_nested_attributes_for :clothings, allow_destroy: true
  geocoded_by :address
  after_validation :geocode, if: :will_save_change_to_address?

  enum status: { created_by_user: 0, assigned_to_merchant: 1, confirm_with_merchant: 2, collected_to_store: 3, In_process_washing: 4, ready_to_pickup: 5 }

  validate :customer_must_be_customer
  validates :address,:notes,:total_price,:clothings, presence: true
  # validate :merchant_must_be_merchant
  # validates :customer_id, uniqueness: { scope: :merchant_id }

  def created_by_user?
    merchant_id.nil? # If merchant_id is nil, it means it was created by a user
  end

  private

  def customer_must_be_customer
    errors.add(:customer, 'must be a customer') unless customer&.customer?
  end

  # def merchant_must_be_merchant
  #   errors.add(:merchant, 'must be a merchant') unless merchant&.merchant?
  # end
end
