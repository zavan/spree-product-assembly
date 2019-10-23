Deface::Override.new(
  virtual_path:     'spree/checkout/_delivery',
  name:             'render_line_item_manifest',
  replace_contents: 'table[data-hook=stock-contents] tbody',
  template:          'line_item_manifest', ship_form: @ship_form
)
