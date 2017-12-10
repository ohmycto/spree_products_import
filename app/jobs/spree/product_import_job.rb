module Spree
  class ProductImportJob < ApplicationJob
    def perform(file_name, email)
      import = Spree::ProductImport.new
      import.file_name = file_name
      import.process_file!

      Spree::ProductImportMailer.finished_email(email, import.import_stats, import.errors.messages).deliver
    end
  end
end