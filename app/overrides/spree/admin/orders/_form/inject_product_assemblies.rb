Deface::Override.new(
  virtual_path: 'spree/admin/orders/_form',
  name: 'inject_product_assemblies',
  insert_bottom: 'div[data-hook=admin_order_form_fields]',
  partial: 'spree/admin/orders/assemblies', locals: { order: @order }
)
