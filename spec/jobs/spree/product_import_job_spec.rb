describe Spree::ProductImportJob, type: :job do
  include ActiveJob::TestHelper

  let!(:shipping_category) { FactoryBot.create(:shipping_category) }
  let!(:stock_location) { FactoryBot.create(:stock_location) }

  let(:import_file) { "spec/fixtures/files/sample-1-valid.csv" }
  let(:user_email) { "email@example.net" }

  it 'calls Spree::ProductImport#process_file! and send email' do
    expect_any_instance_of(Spree::ProductImport).to receive(:process_file!)    
    expect do
      perform_enqueued_jobs { described_class.perform_later(import_file, user_email) }
    end.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end