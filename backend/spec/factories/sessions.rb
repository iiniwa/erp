FactoryBot.define do
  factory :session do
    association :user
    sequence(:session_token) { |n| "token#{n}" }
    session_mode { :normal }
    expires_at { 1.day.from_now }
  end
end
