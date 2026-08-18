FactoryBot.define do
  factory :user do
    sequence(:user_familyname) { |n| "姓#{n}" }
    user_firstname { "太郎" }
    user_familyname_ruby { "せい" }
    user_firstname_ruby { "たろう" }
    user_type { :general }
    user_birth { Date.new(1990, 1, 1) }
    user_id { nil }
    password { "19900101" }
  end
end
