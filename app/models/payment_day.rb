class PaymentDay < ApplicationRecord
  TITLE_MAX = 200
  NOTES_MAX = 4_000
  PER_USER_CAP = 200

  belongs_to :user

  before_validation :normalize

  validates :title, presence: true, length: { maximum: TITLE_MAX }
  validates :notes, length: { maximum: NOTES_MAX }
  validates :due_day, numericality: { only_integer: true, in: 1..31 }
  validate :within_cap, on: :create

  scope :active, -> { where(active: true) }

  def due_on(year, month)
    day = [ due_day, Time.days_in_month(month, year) ].min
    Date.new(year, month, day)
  end

  def as_export
    {
      "title" => title,
      "due_day" => due_day,
      "active" => active,
      "notes" => notes
    }
  end

  private
    def normalize
      self.title = title.to_s.strip
      self.notes = notes.to_s
    end

    def within_cap
      return unless user
      errors.add(:base, :too_many) if user.payment_days.count >= PER_USER_CAP
    end
end
