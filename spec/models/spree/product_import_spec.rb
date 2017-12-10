require 'spec_helper'

describe Spree::ProductImport, type: :model do
  let!(:shipping_category) { FactoryBot.create(:shipping_category) }
  let!(:stock_location) { FactoryBot.create(:stock_location) }
  let(:importer) { described_class.new }

  def last_product
    Spree::Product.last
  end

  describe '#process_file!' do
    context 'with valid products' do
      before do
        importer.file_name = "spec/fixtures/files/sample-1-valid.csv"
      end

      it 'creates a new product with taxon' do
        expect do        
          importer.process_file!
        end.to change { Spree::Product.count }.by(1)
          .and change { Spree::Taxon.count }.by(1)

        expect(importer.import_stats).to              eq({total: 1, created: 1, updated: 0, errors: 0})
        
        expect(last_product.name).to                  eq("Ruby on Rails Bag")
        expect(last_product.description).to           be_present
        expect(last_product.price).to                 eq(22.99)
        expect(last_product.available_on.to_date).to  eq(Date.parse("2017-12-04 14:55:22"))
        expect(last_product.total_on_hand).to         eq(15)
        expect(last_product.total_on_hand).to         eq(15)
        
        expect(last_product.taxons.count).to          eq(1)
        expect(last_product.taxons.first.name).to     eq("Bags")
      end

      it 'updates an existing product and adds taxon to it' do
        existing_product = Spree::Product.create!({
            name: "Test Product",
            slug: "ruby-on-rails-bag",
            available_on: 10.days.ago,
            price: 10.00,
            shipping_category: shipping_category
          })

        expect do
          importer.process_file!
          existing_product.reload
        end.to change { Spree::Product.count }.by(0)
          .and change { existing_product.taxons.count }.by(1)
          .and change { existing_product.name }.to("Ruby on Rails Bag") 
          .and change { existing_product.price }.to(22.99) 
          .and change { existing_product.available_on.to_date }.to(Date.parse("2017-12-04 14:55:22")) 
          .and change { existing_product.total_on_hand }.to(15) 

        expect(importer.import_stats).to eq({total: 1, created: 0, updated: 1, errors: 0})
        expect(existing_product.taxons.first.name).to eq("Bags")
      end

      it 'rolls back line result if something goes wrong' do
        # Simulate case when setting stock total fails after creating a product.
        allow(importer).to receive(:set_stock_total).and_raise(RuntimeError)
        
        expect do
          importer.process_file!
        end.not_to change { [Spree::Product.count, Spree::Taxon.count] }

        expect(importer.import_stats).to eq({total: 1, created: 0, updated: 0, errors: 1})
        expect(importer.errors.messages[:base]).to eq(["Line 1: RuntimeError"])
      end
    end

    context 'with invalid products' do
      def expected_invalid_params_error_text
        I18n.t("activemodel.errors.lines.csv_line", params_list: described_class::REQUIRED_PRODUCT_PARAMS.join(', '))
      end

      before do
        importer.file_name = "spec/fixtures/files/sample-1-valid-3-invalid.csv"
      end

      it 'creates products from valid lines and generates errors on invalid lines' do
        expect do        
          importer.process_file!
        end.to change { Spree::Product.count }.by(1)
          .and change { Spree::Taxon.count }.by(1)

        expect(importer.import_stats).to eq({total: 4, created: 1, updated: 0, errors: 3})
        expect(importer.errors.messages[:base]).to eq([
            "Line 1: #{expected_invalid_params_error_text}", 
            "Line 2: {:price=>[\"must be greater than or equal to 0\"]}", 
            "Line 4: #{expected_invalid_params_error_text}"
          ])
      end
    end
  end
end