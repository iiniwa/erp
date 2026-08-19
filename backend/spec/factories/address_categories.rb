FactoryBot.define do
  factory :address_category do
    sequence(:ac_name) { |n| "カテゴリ#{n}" }
    ac_sort { 1 }
  end
end
