require "spec_helper"

describe Spree::OrderContents do
  describe "#add_to_line_item" do
    context "given a variant which is an assembly" do
      it "creates a PartLineItem for each part of the assembly, assigned to the created LineItem" do
        order = create(:order)
        assembly = create(:product)
        pieces = create_list(:product, 2)
        pieces.each do |piece|
          create(:assemblies_part, assembly: assembly, part: piece.master)
        end

        contents = described_class.new(order)

        line_item = contents.add_to_line_item_with_parts(assembly.master, 1)

        part_line_items = line_item.part_line_items

        expect(part_line_items[0].line_item_id).to eq line_item.id
        expect(part_line_items[0].variant_id).to eq pieces[0].master.id
        expect(part_line_items[0].quantity).to eq 1
        expect(part_line_items[1].line_item_id).to eq line_item.id
        expect(part_line_items[1].variant_id).to eq pieces[1].master.id
        expect(part_line_items[1].quantity).to eq 1
      end
    end

    xcontext "given parts of an assembly" do
      it "creates a PartLineItem for each part, assigned to the created LineItem" do
        order = create(:order)
        products = create_list(:product, 2)

        contents = described_class.new(order)

        line_item = contents.add_to_line_item_with_parts(variant, 1, {
          parts: {
            products[0].id => { "variant_id" => products[0].master.id },
            products[1].id => { "variant_id" => products[1].master.id }
          }
        })

        part_line_items = line_item.part_line_items

        expect(part_line_items[0].line_item_id).to eq line_item.id
        expect(part_line_items[0].variant_id).to eq products[0].master.id
        expect(part_line_items[0].quantity).to eq 1
        expect(part_line_items[1].line_item_id).to eq line_item.id
        expect(part_line_items[1].variant_id).to eq products[1].master.id
        expect(part_line_items[1].quantity).to eq 1
      end
    end
  end
end
