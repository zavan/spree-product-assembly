module Spree
  describe OrderInventory, type: :model do
    let(:order) { Order.create }

    subject { OrderInventory.new(order, order.line_items.first) }

    context "same variant within bundle and as regular product" do
      if Spree.version.to_f < 3.7
        let(:contents) { OrderContents.new(order) }
      end
      let(:guitar) { create(:variant) }
      let(:bass) { create(:variant) }

      let(:bundle) { create(:product) }

      before do
        bundle.master.parts.push([guitar, bass])
        bundle.reload
      end

      if Spree.version.to_f < 3.7
        let!(:bundle_item) { contents.add(bundle.master, 5) }
        let!(:guitar_item) { contents.add(guitar, 3) }
      else
        let!(:bundle_item) { Spree::Cart::AddItem.call(order: order, variant: bundle.master, quantity: 5).value }
        let!(:guitar_item) { Spree::Cart::AddItem.call(order: order, variant: guitar, quantity: 3) }
      end

      let!(:shipment) { order.create_proposed_shipments.first }

      context "completed order" do
        before { order.touch :completed_at }

        it "removes only units associated with provided line item" do
          expect {
            subject.send(:remove_from_shipment, shipment, 5)
          }.not_to change { bundle_item.inventory_units.count }
        end
      end
    end
  end
end
