FactoryBot.define do
  factory :shipping_category, class: 'Spree::ShippingCategory' do
    name { FFaker::Lorem.word }
  end

  factory :stock_location, class: 'Spree::StockLocation' do
    name { FFaker::Lorem.word }
  end
end