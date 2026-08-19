FactoryBot.define do
  factory :address_tel do
    association :address
    at_number { "09000000000" }
    at_label_type { :mobile }
    at_sort { 1 }
  end
end
