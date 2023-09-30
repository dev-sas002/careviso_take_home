# Every registered strategy has to answer the brief the same way: the smallest
# set of packages whose contents are exactly the order. These examples are the
# executable version of that sentence, and both implementations run them.
RSpec.shared_examples "a package selection strategy" do
  def select(order, packages)
    catalog = PackageSelection::Catalog.new(order, packages)
    described_class.call(catalog)
  end

  let(:order) { %w[ProductA ProductB ProductC] }

  it "combines packages that together hold exactly the order" do
    packages = [{ "Package1" => %w[ProductA ProductB] }, { "Package2" => %w[ProductC] }]

    expect(select(order, packages)).to match_array(%w[Package1 Package2])
  end

  it "prefers one package over two that cover the same products" do
    packages = [
      { "Split1" => %w[ProductA ProductB] },
      { "Split2" => %w[ProductC] },
      { "Whole" => order }
    ]

    expect(select(order, packages)).to eq(%w[Whole])
  end

  it "refuses to ship a surplus product" do
    packages = [{ "TooBig" => order + %w[ProductD] }]

    expect(select(order, packages)).to be_nil
  end

  it "refuses to ship the same product twice" do
    packages = [
      { "Overlap1" => %w[ProductA ProductB] },
      { "Overlap2" => %w[ProductB ProductC] }
    ]

    expect(select(order, packages)).to be_nil
  end

  it "picks the non-overlapping combination when an overlapping one is available" do
    packages = [
      { "AB" => %w[ProductA ProductB] },
      { "A" => %w[ProductA] },
      { "C" => %w[ProductC] }
    ]

    expect(select(order, packages)).to match_array(%w[AB C])
  end

  it "returns nil when a product is in no package at all" do
    packages = [{ "Package1" => %w[ProductA ProductB] }]

    expect(select(order, packages)).to be_nil
  end

  it "assembles an order one product at a time when that is all there is" do
    packages = order.map { |name| { "Box#{name}" => [name] } }

    expect(select(order, packages)).to match_array(%w[BoxProductA BoxProductB BoxProductC])
  end

  it "ignores packages that are irrelevant to the order" do
    packages = [
      { "Noise" => %w[ProductX ProductY] },
      { "Package1" => %w[ProductA ProductB] },
      { "Package2" => %w[ProductC] }
    ]

    expect(select(order, packages)).to match_array(%w[Package1 Package2])
  end

  it "is deterministic across runs when several minimal answers exist" do
    packages = [
      { "LeftA" => %w[ProductA] }, { "LeftB" => %w[ProductB ProductC] },
      { "RightA" => %w[ProductA] }, { "RightB" => %w[ProductB ProductC] }
    ]

    answers = Array.new(5) { select(order, packages) }

    expect(answers.uniq.size).to eq(1)
    expect(answers.first.size).to eq(2)
  end

  it "solves the example from the brief" do
    seed_packages = [
      { "Package1" => %w[P1] }, { "Package2" => %w[P2] }, { "Package3" => %w[P3] },
      { "Package4" => %w[P1 P2 P3 P4] }, { "Package5" => %w[P1 P3 P5] },
      { "Package6" => %w[P1 P2] }
    ]

    expect(select(%w[P1 P2 P3], seed_packages)).to match_array(%w[Package6 Package3])
  end
end
