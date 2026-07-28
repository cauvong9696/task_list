class User < ApplicationRecord
  has_secure_password
  has_many :tasks, dependent: :destroy

  normalizes :email, with: ->(value) { value.strip.downcase }

  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
