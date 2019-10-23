module Spree::Cart::AddItemDecorator
  def self.call(order:, variant:, quantity: nil, options: {})
    ApplicationRecord.transaction do
      run :add_to_line_item
      run :populate_part_line_items
      run Spree::Dependencies.cart_recalculate_service.constantize
    end
  end

  private

  def add_to_line_item(order:, variant:, quantity: nil, options: {})
    options ||= {}
    quantity ||= 1
    line_item = Spree::Dependencies.line_item_by_variant_finder.constantize.new.execute(order: order, variant: variant, options: options)

    line_item_created = line_item.nil?
    if line_item.nil?
      opts = ::Spree::PermittedAttributes.line_item_attributes.flatten.each_with_object({}) do |attribute, result|
        result[attribute] = options[attribute]
      end.merge(currency: order.currency).merge(whitelist(options)).delete_if { |_key, value| value.nil? }

      line_item = order.line_items.new(quantity: quantity,
                                      variant: variant,
                                      options: opts)
    else
      line_item.quantity += quantity.to_i
    end

    line_item.target_shipment = options[:shipment] if options.key? :shipment

    return failure(line_item) unless line_item.save

    line_item.reload.update_price

    ::Spree::TaxRate.adjust(order, [line_item]) if line_item_created    
    success(order: order, line_item: line_item, line_item_created: line_item_created, options: options)
  end

  def populate_part_line_items(order:, line_item:, line_item_created:, options:)
    parts = line_item.variant.parts_variants
    parts.each do |part|
      part_line_item = line_item.part_line_items.find_or_initialize_by(
        line_item: line_item,
        variant_id: variant_id_for(part, options)
      )

      part_line_item.update!(quantity: part.count)
    end

    success(order: order, line_item: line_item, line_item_created: line_item_created, options: options)
  end

  def part_variant_ids(line_item)
    line_item.part_line_items.map(&:variant_id)
  end

  def variant_id_for(part, selected_variants)
    if part.variant_selection_deferred?
      selected_variants[part.part.id.to_s]
    else
      part.part.id
    end
  end

  def whitelist(params)
    if params.is_a? ActionController::Parameters
      params.permit(Spree::PermittedAttributes.line_item_attributes)
    else
      params.slice(*Spree::PermittedAttributes.line_item_attributes)
    end
  end  
end

Spree::Cart::AddItem.prepend Spree::Cart::AddItemDecorator if Spree.version.to_f >= 3.7
