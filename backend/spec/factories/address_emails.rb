FactoryBot.define do
  factory :address_email do
    association :address
    ae_email { "test@example.com" }
    ae_sort { 1 }
  end
end
