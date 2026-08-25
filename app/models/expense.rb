class Expense < ApplicationRecord
  TITLE_MAX = 200
  NOTES_MAX = 4_000
  PER_USER_CAP = 10_000
  CATEGORIES = %w[food transport home health leisure other].freeze

  include HasMoney

  belongs_to :user

  before_validation :normalize

  validates :title, presence: true, length: { maximum: TITLE_MAX }
  validates :notes, length: { maximum: NOTES_MAX }
  validates :spent_on, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true
  validate :within_cap, on: :create

  def as_export
    {
      "title" => title,
      "amount_cents" => amount_cents,
      "currency" => currency,
      "spent_on" => spent_on&.iso8601,
      "category" => category,
      "notes" => notes
    }
  end

  private
    def normalize
      self.title = title.to_s.strip
      self.notes = notes.to_s
      self.category = category.to_s.strip
    end

    def within_cap
      return unless user
      errors.add(:base, :too_many) if user.expenses.count >= PER_USER_CAP
    end
end
