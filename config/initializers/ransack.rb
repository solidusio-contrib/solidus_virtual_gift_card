Ransack.configure do |config|
  config.add_predicate 'is',
  arel_predicate: 'eq',
  formatter: proc { |v| v.to_date },
  validator: proc { |v| v.present? },
  type: :string
end
