FactoryBot.define do
  factory :permission_master do
    sequence(:pm_code) { |n| "feature_#{n}" }
    pm_name { "機能" }
    pm_sort { 1 }
  end
end
