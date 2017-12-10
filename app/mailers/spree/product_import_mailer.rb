module Spree
  class ProductImportMailer < BaseMailer

    # Arguments:
    #
    # `recipient_email` - en email where import results should be delivered to;
    # `import_start` - a hash with import results:
    #   {
    #      total:   0,
    #      created: 0,
    #      updated: 0,
    #      errors:  0
    #   }
    # `import_errors` - an array of import errors if any
    def finished_email(recipient_email, import_stats, import_errors = [])
      @import_stats, @import_errors = import_stats, import_errors
      subject = I18n.t("spree_products_import.finished_email.subject")
      mail(to: recipient_email, from: from_address, subject: subject)
    end
  end
end