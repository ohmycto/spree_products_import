Deface::Override.new(virtual_path: 'spree/admin/shared/sub_menu/_product',
  name: 'make_products_menu_active_for_product_imports',
  replace: "erb[loud]:contains('tab :products')",
  text: "<%= tab :products, match_path: \/\\/products|\\/product_imports\/ %>")