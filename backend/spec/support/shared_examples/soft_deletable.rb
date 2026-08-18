RSpec.shared_examples "a soft-deletable model" do
  it "is excluded from the default scope once soft-deleted" do
    subject.soft_delete!
    expect(described_class.exists?(subject.id)).to be false
  end

  it "remains visible via with_deleted" do
    subject.soft_delete!
    expect(described_class.with_deleted.exists?(subject.id)).to be true
  end

  it "appears in only_deleted only after soft deletion" do
    expect(described_class.only_deleted.exists?(subject.id)).to be false
    subject.soft_delete!
    expect(described_class.only_deleted.exists?(subject.id)).to be true
  end

  it "becomes visible again after restore!" do
    subject.soft_delete!
    subject.restore!
    expect(described_class.exists?(subject.id)).to be true
  end
end
