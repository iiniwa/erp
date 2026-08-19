require "rails_helper"

RSpec.describe PermissionMaster do
  it "requires a unique pm_code" do
    create(:permission_master, pm_code: "user_manage")
    duplicate = build(:permission_master, pm_code: "user_manage")

    expect(duplicate).not_to be_valid
  end
end
