FactoryBot.define do
  factory :role_permission do
    association :permission_master
    association :permission_role
  end
end
