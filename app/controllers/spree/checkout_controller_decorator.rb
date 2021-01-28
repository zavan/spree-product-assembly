module Spree
  if defined? Spree::Frontend
    module CheckoutControllerDecorator
      # Override because we don't want to remove unshippable items from the order
      # A bundle itself is an unshippable item
      def before_payment
        @payment_sources = try_spree_current_user.payment_sources if try_spree_current_user&.respond_to?(:payment_sources)
      end
    end
  end
end

Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator

