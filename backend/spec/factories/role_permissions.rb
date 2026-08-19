FactoryBot.define do
  factory :role_permission do
    association :permission_master
    rp_user_type { :general }
  end
end
