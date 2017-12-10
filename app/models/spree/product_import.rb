module Spree
  class ProductImport
    include ActiveModel::Model

    ACCEPTED_FILE_TYPES     = %w(text/csv).freeze
    COLUMNS_SEPARATOR       = ";".freeze
    REQUIRED_PRODUCT_PARAMS = %w(name slug price).freeze

    # A `file_name` attribute can be either 
    # an instance of ActionDispatch::Http::UploadedFile (when uploaded file)
    # or an instance of String (when processing local file).
    attr_accessor :file_name
    attr_reader   :state, :import_stats

    def initialize
      init_attributes
    end

    def process_file!
      # Read CSV line by line from IO object to optimize memory consumption
      # when processing large files.
      CSV.foreach(file_path, headers: true, col_sep: COLUMNS_SEPARATOR) do |row|
        @import_stats[:total] += 1

        # Move to the next line if current row could not be converted
        # to product params (perhaps b/c of missing some required properties).
        next unless product_params = row_to_params(row)

        # Create/update a Product and set stock total in one transaction 
        # to ensure data consistency.
        begin
          ApplicationRecord.transaction do
            product = 
              if existing_product = Spree::Product.find_by(slug: row["slug"])
                update_product(existing_product, product_params)
              else
                create_product(product_params)
              end

            if product
              add_taxon(product, row["category"])
              set_stock_total(product, row["stock_total"].to_i)
            end
          end

          # Commit results to import statistics only after successful transaction.
          @import_stats.merge!(@line_results)
        rescue Exception => e
          log_line_error(e.message)
        end
      end

      @state = "done"
      true
    end

    # Check if file valid and ready for processing.
    def valid?
      valid_file? && valid_content_type?
    end

    # Indicates if import is done.
    def done?
      @state == "done"
    end

    private

    # Updates existing product with provided params.
    # Returns either an instance of updated `Spree::Product`, or `nil`
    # in case of any errors.
    def update_product(product, params)
      product = Core::Importer::Product.new(product, params).update
      if product.errors.empty? 
        @line_results = {updated: @import_stats[:updated] + 1}
        product
      else
        log_line_error(product.errors.messages)
        nil
      end
    end

    # Creates a new product with provided params.
    # Returns either an instance of created `Spree::Product`, or `nil` 
    # in case of any errors.
    def create_product(params)
      product = Core::Importer::Product.new(nil, params).create
      if product.persisted?
        @line_results = {created: @import_stats[:created] + 1}
        product
      else
        log_line_error(product.errors.messages)
        nil
      end
    end

    # TODO:
    # Not sure how to understand `stock_total` column in CSV: 
    # - as a StockMovement (add N products to stock);
    # - as new StockItem count (N products are in stock right now).
    def set_stock_total(product, count)
      stock_item = product.master.stock_items.first_or_initialize
      
      # Variant (a): consider `stock_total` column as StockMovement:
      # Spree::StockMovement.create!(quantity: count, stock_item: stock_item)

      # Variant (b): consider `stock_total` as new count on hand:
      stock_item.count_on_hand = count
      stock_item.save!
    end

    # Adds taxon to product.
    # A new Taxon will be created if not found by provided `taxon_name`.
    def add_taxon(product, taxon_name)
      taxon = Spree::Taxon.where(name: taxon_name).first_or_create!
      product.taxons << taxon
    end

    # Converts a CSV row to product params hash. 
    def row_to_params(row)
      unless REQUIRED_PRODUCT_PARAMS.all? { |param| row[param].present? }
        log_line_error(I18n.t("activemodel.errors.lines.csv_line", params_list: REQUIRED_PRODUCT_PARAMS.join(', ')))
        return nil
      end

      {
        slug:                 row["slug"],
        name:                 row["name"],
        description:          row["description"],
        available_on:         row["availability_date"],
        shipping_category_id: default_shipping_category.id,
        price:                row["price"].sub(',', '.').to_f
      }.compact
    end

    # Take first Shipping Category as default one. 
    # TODO: support providing shipping category in CSV or setting it in import form.
    def default_shipping_category
      Spree::ShippingCategory.first
    end

    # Log line error to class errors to include this in results email.
    def log_line_error(error)
      errors.add(:base, "Line #{@import_stats[:total]}: #{error}")
      @import_stats[:errors] += 1
    end

    # Temp file path in server file system.
    def file_path
      file_name.is_a?(String) ? file_name : file_name.tempfile.path
    end

    # Uploaded file MIME content type.
    def file_content_type
      file_name.content_type
    end

    # Check if any file has been uploaded.
    def valid_file?
      if file_name.present?
        true
      else
        errors.add(:file_name, :empty_file)
        false
      end
    end

    # Check id uploaded file MIME content type belongs to whitelist.
    def valid_content_type?
      if file_content_type.in? ACCEPTED_FILE_TYPES
        true
      else
        errors.add(:file_name, :content_type_not_allowed)
        false
      end
    end

    # Set initial values for class attributes.
    def init_attributes
      # Can be `new` or `done`. Needed just to show import results in view.
      @state = "new"

      # Hash with import statistics:
      #  - total: total lines processed;
      #  - created: count of created products;
      #  - created: count of updated products;
      #  - errors: count of import errors.
      @import_stats = {
          total:   0,
          created: 0,
          updated: 0,
          errors:  0
        }

      @line_results = {}
    end
  end
end
