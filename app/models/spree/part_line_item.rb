module Spree
  class PartLineItem < ActiveRecord::Base
    belongs_to :line_item
    belongs_to :variant, class_name: "Spree::Variant"

    validates :quantity, numericality: { greater_than: 0 }

    validate :quantities_in_range

    delegate :product, to: :line_item

    private

    def quantities_in_range
      return unless product.assembly?

      range = (product.min_parts_quantity..product.max_parts_quantity.presence)
      total_parts = line_item.part_line_items.to_a.sum(&:quantity)

      errors.add(:base, "Invalid subproducts quantity") unless range.include?(total_parts)
    end
  end
end
