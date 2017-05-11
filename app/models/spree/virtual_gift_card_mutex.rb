module Spree
  class VirtualGiftCardMutex < Spree::Base

    class LockFailed < StandardError; end

    belongs_to :gift_card, class_name: "Spree::VirtualGiftCard"

    scope :expired, -> { where(arel_table[:created_at].lteq(Spree::Config[:gift_card_mutex_max_age].seconds.ago)) }

    class << self
      # Obtain a lock on an gift card, execute the supplied block and then release the lock.
      # Raise a LockFailed exception immediately if we cannot obtain the lock.
      # We raise instead of blocking to avoid tying up multiple server processes waiting for the lock.
      def with_lock!(gift_card)
        raise ArgumentError, "gift card must be supplied" if gift_card.nil?

        # limit the maximum lock time just in case a lock is somehow left in place accidentally
        expired.where(gift_card: gift_card).delete_all

        begin
          gift_card_mutex = create!(gift_card: gift_card)
        rescue ActiveRecord::RecordNotUnique
          error = LockFailed.new("Could not obtain lock on gift_card #{gift_card.id}")
          logger.error error.inspect
          raise error
        end

        yield

      ensure
        gift_card_mutex.destroy if gift_card_mutex
      end
    end
  end
end
