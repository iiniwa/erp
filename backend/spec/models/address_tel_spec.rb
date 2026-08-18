require "rails_helper"

RSpec.describe AddressTel do
  describe "emergency contact constraint" do
    it "allows exactly one emergency contact per address" do
      user = create(:user)
      address = create(:address, user: user)
      create(:address_tel, address: address, at_label_type: :emergency, at_sort: 2)

      duplicate = build(:address_tel, address: address, at_label_type: :emergency, at_sort: 3)

      expect { duplicate.save }.to raise_error(ActiveRecord::RecordNotUnique)
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
