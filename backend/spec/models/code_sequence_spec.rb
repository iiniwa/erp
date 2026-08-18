require "rails_helper"

RSpec.describe CodeSequence do
  describe ".next_number_for" do
    it "starts at 1 for a new key and increments on each call" do
      key = "test-#{SecureRandom.hex(4)}"

      expect(described_class.next_number_for(key)).to eq(1)
      expect(described_class.next_number_for(key)).to eq(2)
      expect(described_class.next_number_for(key)).to eq(3)
    end

    it "tracks separate counters per key" do
      key_a = "test-a-#{SecureRandom.hex(4)}"
      key_b = "test-b-#{SecureRandom.hex(4)}"

      described_class.next_number_for(key_a)

      expect(described_class.next_number_for(key_b)).to eq(1)
    end
  end
end
