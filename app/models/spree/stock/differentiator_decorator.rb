module Spree
  module Stock
    Differentiator.class_eval do
      private

      def build_required
        @required = Hash.new(0)
        order.line_items.each do |line_item|
          @required[line_item.variant] = line_item.quantity unless line_item.product.parts.present?
        end
      end
    end
  end
end
