require 'spec_helper'

describe "Orders", type: :feature, js: true do
  stub_authorization!

  let(:order) { create(:order_with_line_items) }
  let(:line_item) { order.line_items.first }
  let(:bundle) { line_item.product }
  let(:parts) { (1..3).map { create(:variant) } }

  before do
    bundle.parts << [parts]
    line_item.update_attributes!(quantity: 3)
    order.reload.create_proposed_shipments
    order.finalize!
  end

  it "allows admin to edit product bundle" do
    change_orders_item_quantity_to 2

    visit spree.edit_admin_order_path(order)

    verify_3_parts_have_their_quantity_set_to 2
  end

  def change_orders_item_quantity_to(n)
    visit spree.edit_admin_order_path(order)

    within("table.product-bundles") do
      find(".edit-line-item").click
      fill_in "quantity", with: n.to_s
      find(".save-line-item").click
    end

    wait_for_ajax
  end

  def verify_3_parts_have_their_quantity_set_to(n)
    within("table.stock-contents") do
      stock_quantities = all(".item-qty-show").map(&:text)

      expect(stock_quantities).to match [
        "#{n} x backordered",
        "#{n} x backordered",
        "#{n} x backordered"
      ]
    end
  end
end
