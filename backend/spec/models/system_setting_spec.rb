require "rails_helper"

RSpec.describe SystemSetting do
  describe ".instance" do
    it "always resolves to the row with system_id = 1" do
      setting = described_class.instance
      setting.company_name = "Iiniwa"
      setting.save!

      expect(described_class.instance.system_id).to eq(1)
      expect(described_class.count).to eq(1)
    end
  end

  it "cannot be created with a system_id other than 1" do
    setting = described_class.new(system_id: 2)
    expect(setting).not_to be_valid
  end

  it "rejects a second row at the database level, even bypassing the model" do
    described_class.instance.save!

    expect do
      described_class.connection.execute("INSERT INTO systems (system_id) VALUES (2)")
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
