FactoryBot.define do
  factory :address_tel do
    association :address
    at_number { "090-0000-0000" }
    at_label_type { :mobile }
    at_sort { 1 }
  end
end
