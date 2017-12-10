module Spree
  module Admin
    class ProductImportsController < Spree::Admin::BaseController

      before_action :authorize_for_import
      before_action :init_import

      def create
        @import.file_name = import_params[:file_name]
        
        if @import.valid?
          Spree::ProductImportJob.perform_later @import.file_name.tempfile.path, try_spree_current_user.email
          flash[:success] = I18n.t(:import_enqueued, scope: :spree_products_import)
        end

        render :new
      end

      private

      def authorize_for_import
        authorize! :update, Product
      end

      def init_import
        @import = Spree::ProductImport.new
      end

      def import_params
        if params[:product_import] && !params[:product_import].empty?
          params.require(:product_import).permit(:file_name)
        else
          {}
        end
      end

    end
  end
end