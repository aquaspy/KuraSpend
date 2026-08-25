class Subscription < ApplicationRecord
  TITLE_MAX = 200
  NOTES_MAX = 4_000
  PER_USER_CAP = 200
  INTERVALS = %w[monthly yearly].freeze

  include HasMoney

  belongs_to :user

  before_validation :normalize

  validates :title, presence: true, length: { maximum: TITLE_MAX }
  validates :notes, length: { maximum: NOTES_MAX }
  validates :interval, inclusion: { in: INTERVALS }
  validates :due_day, numericality: { only_integer: true, in: 1..31 }, allow_nil: true
  validates :billing_month, numericality: { only_integer: true, in: 1..12 }, allow_nil: true
  validate :within_cap, on: :create

  scope :active, -> { where(active: true) }

  def applies_in?(year, month)
    return false unless active?
    return true if monthly?

    (billing_month.presence || 1).to_i == month.to_i
  end

  def monthly?
    interval == "monthly"
  end

  def yearly?
    interval == "yearly"
  end

  def as_export
    {
      "title" => title,
      "amount_cents" => amount_cents,
      "currency" => currency,
      "interval" => interval,
      "due_day" => due_day,
      "billing_month" => billing_month,
      "active" => active,
      "notes" => notes
    }
  end

  private
    def normalize
      self.title = title.to_s.strip
      self.notes = notes.to_s
      self.interval = interval.to_s.presence || "monthly"
      self.due_day = nil if due_day.blank?
      self.billing_month = monthly? ? nil : (billing_month.presence || 1)
    end

    def within_cap
      return unless user
      errors.add(:base, :too_many) if user.subscriptions.count >= PER_USER_CAP
    end
end
