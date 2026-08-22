require "rails_helper"

RSpec.describe AddressTel do
  describe "emergency contact constraint" do
    it "rejects a second emergency contact at the model validation level" do
      user = create(:user)
      address = create(:address, user: user)
      create(:address_tel, address: address, is_emergency: true, at_sort: 2)

      duplicate = build(:address_tel, address: address, is_emergency: true, at_sort: 3)

      expect(duplicate).not_to be_valid
    end

    it "also rejects a second emergency contact at the database level" do
      user = create(:user)
      address = create(:address, user: user)
      create(:address_tel, address: address, is_emergency: true, at_sort: 2)

      # A raw INSERT, bypassing both validations and the
      # before_save :demote_other_emergency_contacts callback (which
      # would otherwise self-heal a conflict created through the model),
      # to confirm the unique index itself still guards against this.
      expect do
        AddressTel.connection.execute(
          "INSERT INTO address_tels (address_id, at_number, at_label_type, at_sort, is_emergency) " \
          "VALUES (#{AddressTel.connection.quote(address.address_id)}, '0300000000', 2, 3, true)"
        )
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects an emergency contact on an address without an associated user" do
      address = create(:address, user: nil)
      tel = build(:address_tel, address: address, is_emergency: true)

      expect(tel).not_to be_valid
    end

    it "is independent of at_label_type — any label can be the emergency contact" do
      user = create(:user)
      address = create(:address, user: user)
      tel = build(:address_tel, address: address, at_label_type: :home, is_emergency: true, at_sort: 2)

      expect(tel).to be_valid
    end

    it "allows multiple non-emergency labels on the same address" do
      address = create(:address)
      create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      other = build(:address_tel, address: address, at_label_type: :main, at_sort: 2)

      expect(other).to be_valid
    end

    it "allows swapping which tel is the emergency contact in a single nested update" do
      user = create(:user)
      address = create(:address, user: user)
      create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      current_emergency = create(:address_tel, address: address, at_label_type: :home, is_emergency: true, at_sort: 2)
      next_emergency = create(:address_tel, address: address, at_label_type: :main, at_sort: 3)

      address.update!(
        address_tels_attributes: [
          { id: current_emergency.at_id, is_emergency: false },
          { id: next_emergency.at_id, is_emergency: true }
        ]
      )

      expect(current_emergency.reload.is_emergency).to be false
      expect(next_emergency.reload.is_emergency).to be true
    end

    it "allows the swap even when the promotion is listed before the demotion" do
      user = create(:user)
      address = create(:address, user: user)
      create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      current_emergency = create(:address_tel, address: address, at_label_type: :home, is_emergency: true, at_sort: 2)
      next_emergency = create(:address_tel, address: address, at_label_type: :main, at_sort: 3)

      # accepts_nested_attributes_for saves records in submission order,
      # not at_sort order, so the promotion (which would otherwise try to
      # save while the old row is still `true` in the DB) is listed first
      # on purpose here.
      address.update!(
        address_tels_attributes: [
          { id: next_emergency.at_id, is_emergency: true },
          { id: current_emergency.at_id, is_emergency: false }
        ]
      )

      expect(next_emergency.reload.is_emergency).to be true
      expect(current_emergency.reload.is_emergency).to be false
    end

    it "allows destroying the current emergency contact while promoting another in the same update" do
      user = create(:user)
      address = create(:address, user: user)
      create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      current_emergency = create(:address_tel, address: address, at_label_type: :home, is_emergency: true, at_sort: 2)
      next_emergency = create(:address_tel, address: address, at_label_type: :main, at_sort: 3)

      address.update!(
        address_tels_attributes: [
          { id: current_emergency.at_id, _destroy: true },
          { id: next_emergency.at_id, is_emergency: true }
        ]
      )

      expect(AddressTel.exists?(current_emergency.at_id)).to be false
      expect(next_emergency.reload.is_emergency).to be true
    end
  end

  describe "primary promotion on destroy" do
    it "promotes the next-lowest sort to 1 for a non-employee address" do
      address = create(:address, user: nil)
      primary = create(:address_tel, address: address, at_label_type: :main, at_sort: 1)
      secondary = create(:address_tel, address: address, at_label_type: :fax, at_sort: 2)

      primary.destroy!

      expect(secondary.reload.at_sort).to eq(1)
    end

    it "refuses to destroy an employee's primary mobile tel when a non-mobile tel would become primary" do
      user = create(:user)
      address = create(:address, user: user)
      mobile = create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      main = create(:address_tel, address: address, at_label_type: :main, at_sort: 2)

      expect { mobile.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(AddressTel.exists?(mobile.at_id)).to be true
      expect(main.reload.at_sort).to eq(2)
    end

    it "allows destroying the primary mobile tel when another mobile tel remains" do
      user = create(:user)
      address = create(:address, user: user)
      mobile = create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      other_mobile = create(:address_tel, address: address, at_label_type: :mobile, at_sort: 2)

      mobile.destroy!

      expect(other_mobile.reload.at_sort).to eq(1)
    end

    it "promotes a mobile tel past a non-mobile one that sorts lower" do
      user = create(:user)
      address = create(:address, user: user)
      mobile = create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      main = create(:address_tel, address: address, at_label_type: :main, at_sort: 2)
      other_mobile = create(:address_tel, address: address, at_label_type: :mobile, at_sort: 3)

      mobile.destroy!

      expect(other_mobile.reload.at_sort).to eq(1)
      expect(main.reload.at_sort).to eq(2)
    end
  end

  describe "free-form label" do
    it "requires at_label_free when at_label_type is free" do
      tel = build(:address_tel, at_label_type: :free, at_label_free: nil)
      expect(tel).not_to be_valid
    end

    it "is valid with at_label_free set" do
      tel = build(:address_tel, at_label_type: :free, at_label_free: "取引先直通")
      expect(tel).to be_valid
    end
  end
end
