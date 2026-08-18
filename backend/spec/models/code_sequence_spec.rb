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

    it "never returns the same number for concurrent callers sharing a key",
      use_transactional_tests: false do
      key = "test-concurrent-#{SecureRandom.hex(4)}"
      thread_count = 20
      numbers = Array.new(thread_count)

      threads = Array.new(thread_count) do |i|
        Thread.new do
          Rails.application.executor.wrap do
            numbers[i] = described_class.next_number_for(key)
          end
        end
      end
      threads.each(&:join)

      expect(numbers.uniq.length).to eq(thread_count)
      expect(numbers.sort).to eq((1..thread_count).to_a)
    ensure
      CodeSequence.where(sequence_key: key).delete_all
    end

    it "raises once the monthly limit is reached" do
      key = "test-exhausted-#{SecureRandom.hex(4)}"
      described_class.create!(sequence_key: key, last_number: described_class::MAX_NUMBER)

      expect { described_class.next_number_for(key) }.to raise_error(described_class::Exhausted)
    end
  end
end
