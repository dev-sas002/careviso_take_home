# Idempotent: `rails db:seed` can be run repeatedly (the Docker entrypoint runs
# it on boot) without duplicating anything.
#
# Two datasets are loaded:
#
#   1. The example from the brief, so the documented answer can be checked by
#      hand: an order of P1, P2, P3 ships as Package6 (P1, P2) + Package3 (P3).
#   2. A small clinical-supplies catalogue, so the app is not a set of empty
#      tables on first boot.
def product!(name)
  Product.find_or_create_by!(name: name)
end

def package!(name, product_names)
  package = Package.find_or_create_by!(name: name)
  package.products = product_names.map { |product_name| product!(product_name) }
  package
end

def order!(product_names)
  products = product_names.map { |product_name| product!(product_name) }
  Order.find_each do |existing|
    return existing if existing.products.map(&:name).sort == product_names.sort
  end
  Order.create!(products: products)
end

puts "Seeding the example from the brief"

%w[P1 P2 P3 P4 P5].each { |name| product!(name) }

package!("Package1", %w[P1])
package!("Package2", %w[P2])
package!("Package3", %w[P3])
package!("Package4", %w[P1 P2 P3 P4])
package!("Package5", %w[P1 P3 P5])
package!("Package6", %w[P1 P2])

order!(%w[P1 P2 P3])

puts "Seeding a clinical-supplies catalogue"

CATALOGUE = [
  "Specimen Kit", "Collection Tube", "Prepaid Mailer", "Biohazard Bag",
  "Requisition Form", "Alcohol Swab", "Sterile Gauze", "Lancet"
].freeze

CATALOGUE.each { |name| product!(name) }

package!("Draw Kit",          ["Collection Tube", "Alcohol Swab", "Lancet"])
package!("Return Pack",       ["Prepaid Mailer", "Biohazard Bag"])
package!("Paperwork Pack",    ["Requisition Form"])
package!("Phlebotomy Bundle", ["Collection Tube", "Alcohol Swab", "Lancet", "Sterile Gauze"])
package!("Patient Kit",       ["Specimen Kit", "Prepaid Mailer", "Biohazard Bag", "Requisition Form"])
package!("Swab Pair",         ["Alcohol Swab", "Sterile Gauze"])
package!("Mailer Only",       ["Prepaid Mailer"])
package!("Tube Only",         ["Collection Tube"])

# Ships exactly as Draw Kit + Return Pack + Paperwork Pack.
order!(["Collection Tube", "Alcohol Swab", "Lancet", "Prepaid Mailer", "Biohazard Bag", "Requisition Form"])
# Ships as Patient Kit alone, rather than as three smaller packages.
order!(["Specimen Kit", "Prepaid Mailer", "Biohazard Bag", "Requisition Form"])
# Has no exact shipment: nothing holds Sterile Gauze without something surplus.
order!(["Specimen Kit", "Sterile Gauze"])

puts "Seeded #{Product.count} products, #{Package.count} packages, #{Order.count} orders"
