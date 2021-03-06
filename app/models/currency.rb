class Currency < ApplicationRecord
  extend Enumerize

  validates :name, :code, :symbol, :country, presence: true
  validates :name, length: { maximum: 20 }
  validates :code, length: { is: 3 }
  validates :symbol, length: { maximum: 10 }
  validates :country, length: { maximum: 25 }
  validates :code, uniqueness: true

  enumerize :definition, in: %i(money crypto_coin)

  scope :ballast, ->() { where(default: true).limit(1) }

  before_validation :validate_default

  after_create :test_integrity_with_conversor_service

  before_destroy :validate_permited_to_destroy

  def crypto_coin?
    self.definition == 'crypto_coin'
  end

  private

  def validate_default
    if default_change_to_be_saved == [true, false]
      errors.add(:default, 'you can\'t change default option!!!')
      return
    end

    if default_change_to_be_saved and Currency.ballast.first.present?
      errors.add(:default, 'ballast already setted!!!')
    end
  end

  def test_integrity_with_conversor_service
    service = CurrencyConversorService.new(from: self.code, to: 'USD', amount: 1)
    service.execute
  rescue => error
    Rails.logger.error("Create! Integrity Error: #{error}")
    self.destroy!
    raise CreateTestIntegrityError
  end

  def validate_permited_to_destroy
    raise NotAllowedToDestroyError if self.default == true
  end

  protected

  class CreateTestIntegrityError < StandardError ; end
  class NotAllowedToDestroyError < StandardError ; end
end
