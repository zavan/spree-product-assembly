require 'spec_helper'

module Spree
  describe OrderInventoryAssembly do
    describe "#verify" do
      context "when a shipment is provided" do
        context "when the bundle is created" do
          it "produces inventory units for each item in the bundle" do
            shipment, line_item, variants = create_line_item_for_bundle(
              parts: [ { count: 1 }, { count: 1 }, { count: 3 } ]
            )
            inventory = OrderInventoryAssembly.new(line_item)
            inventory.verify(shipment)
            expect(inventory.inventory_units.count).to eq 5

            expect(inventory.inventory_units[0].variant).to eq variants[0]
            expect(inventory.inventory_units[1].variant).to eq variants[1]
            inventory.inventory_units[2..4].each do |unit|
              expect(unit.variant).to eq variants[2]
            end
          end
        end

        context "when the bundle quantity is increased" do
          it "adds [difference in quantity] sets of inventory units" do
            shipment, line_item, variants = create_line_item_for_bundle(
              parts: [ { count: 1 }, { count: 1 }, { count: 3 } ]
            )
            inventory = OrderInventoryAssembly.new(line_item)
            inventory.verify(shipment)

            line_item.quantity = 2

            inventory.verify(shipment)

            expect(inventory.inventory_units.count).to eq 10

            expect(inventory.inventory_units[0].variant).to eq variants[0]
            expect(inventory.inventory_units[1].variant).to eq variants[1]
            inventory.inventory_units[2..4].each do |unit|
              expect(unit.variant).to eq variants[2]
            end

            expect(inventory.inventory_units[5].variant).to eq variants[0]
            expect(inventory.inventory_units[6].variant).to eq variants[1]
            inventory.inventory_units[7..9].each do |unit|
              expect(unit.variant).to eq variants[2]
            end
          end
        end

        context "when the bundle quantity is decreased" do
          it "removes [difference in quantity] sets of inventory units" do
            shipment, line_item, variants = create_line_item_for_bundle(
              line_item_quantity: 2,
              parts: [ { count: 1 }, { count: 1 }, { count: 3 } ]
            )
            inventory = OrderInventoryAssembly.new(line_item)
            inventory.verify(shipment)

            line_item.quantity = 1

            inventory.verify(shipment)

            expect(inventory.inventory_units.count).to eq 5

            expect(inventory.inventory_units[0].variant).to eq variants[0]
            expect(inventory.inventory_units[1].variant).to eq variants[1]
            inventory.inventory_units[2..4].each do |unit|
              expect(unit.variant).to eq variants[2]
            end
          end
        end
      end

      context "when a shipment is not provided" do
        context "when the bundle is created" do
          it "produces inventory units for each item in the bundle" do
            _shipment, line_item, variants = create_line_item_for_bundle(
              parts: [ { count: 1 }, { count: 1 }, { count: 3 } ]
            )
            inventory = OrderInventoryAssembly.new(line_item)
            inventory.verify()

            expect(inventory.inventory_units.count).to eq 5

            expect(inventory.inventory_units[0].variant).to eq variants[0]
            expect(inventory.inventory_units[1].variant).to eq variants[1]
            inventory.inventory_units[2..4].each do |unit|
              expect(unit.variant).to eq variants[2]
            end
          end
        end

        context "when the bundle quantity is increased" do
          it "adds [difference in quantity] sets of inventory units" do
            _shipment, line_item, variants = create_line_item_for_bundle(
              parts: [ { count: 1 }, { count: 1 }, { count: 3 } ]
            )
            inventory = OrderInventoryAssembly.new(line_item)
            inventory.verify

            line_item.quantity = 2

            inventory.verify

            expect(inventory.inventory_units.count).to eq 10

            expect(inventory.inventory_units[0].variant).to eq variants[0]
            expect(inventory.inventory_units[1].variant).to eq variants[1]
            inventory.inventory_units[2..4].each do |unit|
              expect(unit.variant).to eq variants[2]
            end

            expect(inventory.inventory_units[5].variant).to eq variants[0]
            expect(inventory.inventory_units[6].variant).to eq variants[1]
            inventory.inventory_units[7..9].each do |unit|
              expect(unit.variant).to eq variants[2]
            end
          end
        end

        context "when the bundle quantity is decreased" do
          it "removes [difference in quantity] sets of inventory units" do
            _shipment, line_item, variants = create_line_item_for_bundle(
              line_item_quantity: 2,
              parts: [ { count: 1 }, { count: 1 }, { count: 3 } ]
            )
            inventory = OrderInventoryAssembly.new(line_item)
            inventory.verify

            line_item.quantity = 1

            inventory.verify

            expect(inventory.inventory_units.count).to eq 5

            expect(inventory.inventory_units[0].variant).to eq variants[0]
            expect(inventory.inventory_units[1].variant).to eq variants[1]
            inventory.inventory_units[2..4].each do |unit|
              expect(unit.variant).to eq variants[2]
            end
          end

          context "when the bundle is in both shipped and unshipped shipments" do
            it "removes the items in the bundle from only the unshipped shipments" do
              unshipped_shipment, line_item, variants = create_line_item_for_bundle(
                line_item_quantity: 2,
                parts: [ { count: 1 }, { count: 1 }, { count: 3 } ]
              )
              shipped_shipment = create(:shipment, state: 'shipped')
              InventoryUnit.all[0..2].each do |unit|
                unit.update_attribute(:shipment_id, shipped_shipment.id)
              end

              inventory = OrderInventoryAssembly.new(line_item)

              line_item.quantity = 1
              inventory.verify

              expect(inventory.inventory_units.count).to eq 6

              unshipped_units = unshipped_shipment.inventory_units
              expect(unshipped_units.count).to eq 3
              unshipped_units.each do |unit|
                expect(unit.variant).to eq variants[2]
              end

              shipped_units = shipped_shipment.inventory_units
              expect(shipped_units.count).to eq 3
              shipped_units[0..1].each do |unit|
                expect(unit.variant).to eq variants[0]
              end
              expect(shipped_units[2].variant).to eq variants[1]
            end
          end
        end
      end
    end

    def create_line_item_for_bundle(args)
      parts = args.fetch(:parts)
      line_item_quantity = args.fetch(:line_item_quantity, 1)
      order = create(:order, completed_at: Time.now)
      shipment = create(:shipment, order: order)
      bundle = create(:product, name: "Bundle")

      variants = []
      parts.each_with_index do |part, i|
        product = create(:product, name: "Part #{i + 1}")
        variant = create(:variant, product: product, sku: "PART#{i + 1}")
        variants << variant
        create(:assemblies_part, part.merge(assembly: bundle, part: variant))
      end

      bundle.reload

      line_item = create(
        :line_item,
        order: order,
        variant: bundle.master,
        quantity: line_item_quantity
      )
      line_item.reload

      [shipment, line_item, variants]
    end
  end
end
