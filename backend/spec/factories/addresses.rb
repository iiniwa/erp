FactoryBot.define do
  factory :address do
    association :address_category
    address_name { "取引先株式会社" }
    address_ruby { "とりひきさきかぶしきがいしゃ" }
    user { nil }
  end
end
