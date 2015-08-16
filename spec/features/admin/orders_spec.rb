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
    visit spree.edit_admin_order_path(order)

    within("table.product-bundles") do
      find(".edit-line-item").click
      fill_in "quantity", with: 2
      find(".save-line-item").click
    end

    wait_for_ajax

    visit spree.edit_admin_order_path(order)

    within("table.stock-contents") do
      stock_quantities = all(".item-qty-show").map(&:text)

      expect(stock_quantities).to match [
        "2 x backordered",
        "2 x backordered",
        "2 x backordered"
      ]
    end
  end
end
