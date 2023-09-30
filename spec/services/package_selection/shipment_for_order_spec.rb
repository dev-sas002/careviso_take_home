require "rails_helper"

RSpec.describe PackageSelection::ShipmentForOrder do
  let!(:p1) { create(:product, name: "P1") }
  let!(:p2) { create(:product, name: "P2") }
  let!(:p3) { create(:product, name: "P3") }
  let!(:p4) { create(:product, name: "P4") }

  let!(:order) { create(:order, products: [p1, p2, p3]) }

  def count_queries
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      queries << payload[:sql] unless payload[:name].to_s.in?(%w[SCHEMA TRANSACTION CACHE])
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it "returns the names of the smallest exact shipment" do
    create(:package, name: "Package1", products: [p1])
    create(:package, name: "Package2", products: [p2])
    create(:package, name: "Package3", products: [p3])
    create(:package, name: "Package6", products: [p1, p2])

    expect(described_class.call(order)).to match_array(%w[Package6 Package3])
  end

  it "returns nil when nothing ships the order exactly" do
    create(:package, name: "TooMuch", products: [p1, p2, p3, p4])

    expect(described_class.call(order)).to be_nil
  end

  it "returns nil when there are no packages at all" do
    expect(described_class.call(order)).to be_nil
  end

  describe "the catalogue query" do
    before do
      create(:package, name: "Package6", products: [p1, p2])
      create(:package, name: "Package3", products: [p3])
      10.times { |i| create(:package, name: "Irrelevant#{i}", products: [p4]) }
    end

    it "loads the whole catalogue in a single query, not one per package" do
      queries = count_queries { described_class.call(order) }
      catalogue_queries = queries.grep(/FROM "packages"/)

      expect(catalogue_queries.size).to eq(1)
    end

    it "never loads packages that hold an unordered product" do
      selector = described_class.new(order)
      selector.call

      catalogue = selector.send(:available_packages)
      expect(catalogue.keys).to contain_exactly("Package6", "Package3")
    end
  end

  describe "caching" do
    around do |example|
      original = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original
    end

    before do
      create(:package, name: "Package6", products: [p1, p2])
      create(:package, name: "Package3", products: [p3])
    end

    it "does not re-run the search for identical inputs" do
      expect(PackageSelector).to receive(:select_optimal_packages).once.and_call_original

      2.times { described_class.call(order) }
    end

    it "re-runs the search once the catalogue changes" do
      described_class.call(order)
      create(:package, name: "Everything", products: [p1, p2, p3])

      expect(described_class.call(order)).to eq(%w[Everything])
    end

    it "re-runs the search once the order changes" do
      described_class.call(order)
      order.update!(products: [p1, p2])

      expect(described_class.call(order)).to eq(%w[Package6])
    end

    it "caches 'no exact shipment' as well as a positive answer" do
      unshippable = create(:order, products: [p4])

      expect(described_class.call(unshippable)).to be_nil
      expect(PackageSelector).not_to receive(:select_optimal_packages)
      expect(described_class.call(unshippable)).to be_nil
    end
  end

  describe "strategies" do
    before do
      create(:package, name: "Package6", products: [p1, p2])
      create(:package, name: "Package3", products: [p3])
    end

    it "passes the requested strategy through" do
      expect(described_class.call(order, strategy: :brute_force)).to match_array(%w[Package6 Package3])
    end
  end
end
