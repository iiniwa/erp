require "rails_helper"

RSpec.describe AddressTel do
  describe "emergency contact constraint" do
    it "rejects a second emergency contact at the model validation level" do
      user = create(:user)
      address = create(:address, user: user)
      create(:address_tel, address: address, at_label_type: :emergency, at_sort: 2)

      duplicate = build(:address_tel, address: address, at_label_type: :emergency, at_sort: 3)

      expect(duplicate).not_to be_valid
    end

    it "also rejects a second emergency contact at the database level" do
      user = create(:user)
      address = create(:address, user: user)
      create(:address_tel, address: address, at_label_type: :emergency, at_sort: 2)

      duplicate = build(:address_tel, address: address, at_label_type: :emergency, at_sort: 3)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects an emergency contact on an address without an associated user" do
      address = create(:address, user: nil)
      tel = build(:address_tel, address: address, at_label_type: :emergency)

      expect(tel).not_to be_valid
    end

    it "allows multiple non-emergency labels on the same address" do
      address = create(:address)
      create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      other = build(:address_tel, address: address, at_label_type: :main, at_sort: 2)

      expect(other).to be_valid
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

    it "does not promote a non-mobile tel to primary on an employee address" do
      user = create(:user)
      address = create(:address, user: user)
      mobile = create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      main = create(:address_tel, address: address, at_label_type: :main, at_sort: 2)

      mobile.destroy!

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
