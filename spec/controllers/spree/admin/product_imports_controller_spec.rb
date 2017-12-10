require 'spec_helper'

describe Spree::Admin::ProductImportsController, type: :controller do
  stub_authorization!

  render_views

  context '#new' do
    it 'should display a file upload form' do
      get :new
      expect(response).to have_http_status(200)
      expect(response.body).to have_content(I18n.t("spree_products_import.file_name"))
    end
  end

  context '#create' do
    it 'should show error when file was not provided' do
      expect_any_instance_of(Spree::ProductImport).not_to receive(:process_file!)

      post :create, params: {product_import: {file_name: nil}}
      expect(response).to have_http_status(200)
      expect(response.body).to have_content(I18n.t("activemodel.errors.models.spree/product_import.attributes.file_name.empty_file"))
    end

    it 'should show error when provided file has unsupported MIME type' do
      expect_any_instance_of(Spree::ProductImport).not_to receive(:process_file!)

      file = fixture_file_upload('files/sample-1-valid.csv', 'text/plain')

      post :create, params: {product_import: {file_name: file}}
      expect(response).to have_http_status(200)
      expect(response.body).to have_content(I18n.t("activemodel.errors.models.spree/product_import.attributes.file_name.content_type_not_allowed"))
    end

    it 'should enqueue import and show message about that' do
      ActiveJob::Base.queue_adapter = :test
      
      user = create(:user)
      allow(controller).to receive_messages spree_current_user: user

      file = fixture_file_upload("files/sample-1-valid.csv", 'text/csv')

      expect do
        post :create, params: {product_import: {file_name: file}}      
      end.to have_enqueued_job(Spree::ProductImportJob)

      expect(response).to have_http_status(200)
      expect(response.body).to have_content(I18n.t(:import_enqueued, scope: :spree_products_import))
    end
  end
end