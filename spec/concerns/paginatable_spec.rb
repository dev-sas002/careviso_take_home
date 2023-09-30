require "rails_helper"

RSpec.describe Paginatable::Pagination do
  subject(:pagination) { described_class.new(page: 2, per_page: 25, total_count: 60) }

  it "reports where it is in the collection" do
    expect(pagination.total_pages).to eq(3)
    expect(pagination.offset).to eq(25)
    expect(pagination.range).to eq(26..50)
    expect(pagination).not_to be_first_page
    expect(pagination).not_to be_last_page
  end

  it "always reports at least one page, even when empty" do
    empty = described_class.new(page: 1, per_page: 25, total_count: 0)

    expect(empty.total_pages).to eq(1)
    expect(empty).to be_empty
    expect(empty).to be_first_page
    expect(empty).to be_last_page
  end

  it "clips the last page to the real number of records" do
    last = described_class.new(page: 3, per_page: 25, total_count: 60)

    expect(last.range).to eq(51..60)
    expect(last).to be_last_page
  end
end
