FactoryBot.define do
  factory :permission_role do
    sequence(:role_name) { |n| "役割#{n}" }
    role_sort { 1 }
  end
end
