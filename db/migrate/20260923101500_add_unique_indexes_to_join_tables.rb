# The join tables shipped with one single-column index per foreign key and no
# uniqueness constraint, so the same product could be attached to the same order
# (or package) twice. That is not just untidy: "ship each ordered product exactly
# once" is the rule the whole exercise turns on, and a duplicate join row makes
# the order's product list disagree with itself.
#
# The composite unique index also subsumes the standalone `order_id` /
# `package_id` index — Postgres can use a multi-column index for a leading-column
# lookup — so those are dropped rather than kept alongside it.
class AddUniqueIndexesToJoinTables < ActiveRecord::Migration[7.0]
  def up
    deduplicate!(:order_products, :order_id)
    deduplicate!(:package_products, :package_id)

    remove_index :order_products, column: :order_id
    add_index :order_products, %i[order_id product_id], unique: true

    remove_index :package_products, column: :package_id
    add_index :package_products, %i[package_id product_id], unique: true
  end

  def down
    remove_index :order_products, column: %i[order_id product_id]
    add_index :order_products, :order_id

    remove_index :package_products, column: %i[package_id product_id]
    add_index :package_products, :package_id
  end

  private

  def deduplicate!(table, owner_column)
    execute(<<~SQL.squish)
      DELETE FROM #{table} duplicate
      USING #{table} original
      WHERE duplicate.id > original.id
        AND duplicate.#{owner_column} = original.#{owner_column}
        AND duplicate.product_id = original.product_id
    SQL
  end
end
