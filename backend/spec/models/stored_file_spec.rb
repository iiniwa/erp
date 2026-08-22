require "rails_helper"

RSpec.describe StoredFile do
  subject { create(:stored_file) }

  it_behaves_like "a soft-deletable model"

  it "requires a file_path" do
    file = build(:stored_file, file_path: nil)
    expect(file).not_to be_valid
  end

  it "requires a file_name" do
    file = build(:stored_file, file_name: nil)
    expect(file).not_to be_valid
  end
end
