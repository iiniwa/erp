FactoryBot.define do
  factory :stored_file do
    sequence(:file_path) { |n| "general/#{n}-test.png" }
    file_name { "test.png" }
    content_type { "image/png" }
    file_size { 1234 }
    file_type { :general }
  end
end
