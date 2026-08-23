require "rails_helper"

RSpec.describe "db/seeds.rb" do
  it "creates the fixed system administrator on first run" do
    expect { load Rails.root.join("db/seeds.rb") }.to change(User, :count).by(1)

    admin = User.system_admin.sole
    expect(admin.user_id).to be_nil
    expect(admin.user_must_change_password).to be true
    expect(admin.authenticate_password(admin.user_birth.strftime("%Y%m%d"))).to be true

    address = admin.addresses.sole
    expect(address.address_tels.sole).to be_mobile
  end

  it "is idempotent" do
    load Rails.root.join("db/seeds.rb")

    expect { load Rails.root.join("db/seeds.rb") }.not_to change(User, :count)
  end

  it "seeds a view-only starter role for the default features" do
    load Rails.root.join("db/seeds.rb")

    user_manage = PermissionMaster.find_by!(pm_code: "user_manage")
    staff_role = PermissionRole.find_by!(role_name: "スタッフ")
    staff_permission = user_manage.role_permissions.find_by(permission_role: staff_role)
    expect(staff_permission).to have_attributes(rp_can_view: true, rp_can_create: false)
  end

  it "does not create a duplicate admin if the existing one was soft-deleted" do
    load Rails.root.join("db/seeds.rb")
    User.system_admin.sole.soft_delete!

    expect { load Rails.root.join("db/seeds.rb") }.to raise_error(/soft-deleted/)
    expect(User.with_deleted.system_admin.count).to eq(1)
  end

  it "creates only one admin even when db:seed runs concurrently", use_transactional_tests: false do
    thread_count = 5

    threads = Array.new(thread_count) do
      Thread.new do
        Rails.application.executor.wrap do
          load Rails.root.join("db/seeds.rb")
        end
      end
    end
    threads.each(&:join)

    expect(User.with_deleted.system_admin.count).to eq(1)
  ensure
    # Delete only what this example itself created: the admin, its address
    # and phone number, and the code_sequences rows their numbering
    # consumed (including any burned by threads that lost the race and
    # retried). The shared "社内" AddressCategory is left alone.
    admin = User.system_admin.first
    if admin
      address = admin.addresses.first
      if address
        # :delete_all overrides the association's default dependent
        # strategy (nullify), which would otherwise try to null out
        # address_tels.address_id and fail its NOT NULL constraint.
        address.address_tels.delete_all(:delete_all)
        address.delete
        CodeSequence.where(sequence_key: "8-#{Time.current.strftime('%y%m')}").delete_all
      end
      admin.delete
      CodeSequence.where(sequence_key: "9-#{Time.current.strftime('%y%m')}").delete_all
    end
  end
end
