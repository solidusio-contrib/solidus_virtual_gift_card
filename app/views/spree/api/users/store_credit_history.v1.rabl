collection @store_credit_events => :store_credit_events

attributes *store_credit_history_attributes
node(:order_number) { |event| event.order.try(:number) }
