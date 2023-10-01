puts 'Creating Products'

p1 = Product.create!(name: 'P1')
p2 = Product.create!(name: 'P2')
p3 = Product.create!(name: 'P3')
p4 = Product.create!(name: 'P4')
p5 = Product.create!(name: 'P5')

puts 'Create the packages and associate them with the products'

package1 = Package.create!(name: 'Package1')
package1.products << p1

package2 = Package.create!(name: 'Package2')
package2.products << p2

package3 = Package.create!(name: 'Package3')
package3.products << p3

package4 = Package.create!(name: 'Package4')
package4.products << [p1, p2, p3, p4]

package5 = Package.create!(name: 'Package5')
package5.products << [p1, p3, p5]

package6 = Package.create!(name: 'Package6')
package6.products << [p1, p2]

puts 'Create an order and associate it with the desired products'
order = Order.create!
order.products << [p1, p2, p3]
