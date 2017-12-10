Deface::Override.new(virtual_path: 'spree/admin/products/index',
  name: 'add_csv_import_button_to_products_index',
  insert_after: "erb[loud]:contains('admin_new_product')",
  text: "
    <%= button_link_to t(:import_products, scope: :spree_products_import), 
                       new_admin_product_import_url, 
                       { class: 'btn-secondary', icon: 'import', id: 'admin_import_products' } %>
  ")