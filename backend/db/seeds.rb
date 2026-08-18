# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Seeds the single fixed system administrator account required by
# docs/ERP_phase1_spec.md section 13.1: user_id is left NULL, the initial
# password is the admin's 8-digit birthdate, and the first login must happen
# via the primary mobile number recorded in t.address_tel.
#
# All values are overridable via ENV so operators can seed real data without
# editing this file; the defaults are placeholders to be corrected from the
# admin screens after first login (see spec section 13.2).
ActiveRecord::Base.transaction do
  # .with_deleted: a soft-deleted admin must still be found here, otherwise
  # a reseed would create a second :system_admin record alongside it.
  admin = User.with_deleted.find_or_initialize_by(user_type: :system_admin)

  if admin.persisted? && admin.soft_deleted?
    raise "The fixed system administrator account has been soft-deleted; " \
          "restore it manually (User#restore!) before reseeding"
  end

  if admin.new_record?
    admin_birth = Date.parse(ENV.fetch("SEED_ADMIN_BIRTH", "1990-01-01"))

    admin.assign_attributes(
      user_familyname: ENV.fetch("SEED_ADMIN_FAMILYNAME", "管理"),
      user_firstname: ENV.fetch("SEED_ADMIN_FIRSTNAME", "太郎"),
      user_familyname_ruby: ENV.fetch("SEED_ADMIN_FAMILYNAME_RUBY", "かんり"),
      user_firstname_ruby: ENV.fetch("SEED_ADMIN_FIRSTNAME_RUBY", "たろう"),
      user_birth: admin_birth,
      user_must_change_password: true
    )
    admin.password = admin_birth.strftime("%Y%m%d")
    admin.save!

    # t.address_category has no general-purpose seed data by policy (spec
    # section 7, item 5), but t.address.address_category_id is a required
    # column, so the admin's own address book entry needs a category to
    # point at. Create the minimal "in-house" category for that purpose.
    in_house_category = AddressCategory.find_or_create_by!(ac_name: "社内") do |category|
      category.ac_sort = 1
    end

    address = Address.create!(
      address_category: in_house_category,
      address_name: "#{admin.user_familyname} #{admin.user_firstname}",
      address_ruby: "#{admin.user_familyname_ruby} #{admin.user_firstname_ruby}",
      user: admin
    )

    address.address_tels.create!(
      at_number: ENV.fetch("SEED_ADMIN_MOBILE_NUMBER", "00000000000"),
      at_label_type: :mobile,
      at_sort: 1
    )
  end
end
