# @deprecated  Create Model-specific Controllers instead ie. ArticlesController, ETDController, etc.
require 'deprecation'

module Hydra::Controller::AssetsControllerBehavior
  extend ActiveSupport::Concern

  include Blacklight::SolrHelper
  include Hydra::Controller::RepositoryControllerBehavior
  include Hydra::AssetsControllerHelper
  include Blacklight::Catalog
  extend Deprecation

  included do
    Deprecation.warn Hydra::Controller::AssetsControllerBehavior, "Hydra::Controller::AssetsControllerBehavior will be removed in hydra-head 6.0"
    helper :hydra
    before_filter :search_session, :history_session
    before_filter :load_document, :only => :update # allows other filters to operate on the document before the update method is called

    include Hydra::SubmissionWorkflow
    include Hydra::AccessControlsEnforcement
    
    
    prepend_before_filter :sanitize_update_params, :only=>:update
    before_filter :check_embargo_date_format, :only=>:update
    before_filter :enforce_access_controls
  end
      
  def show
    if params.has_key?("field")
      
      @response, @document = get_solr_response_for_doc_id
      result = @document["#{params["field"]}_t"]
      unless result.nil?
        if params.has_key?("field_index")
          result = result[params["field_index"].to_i-1]
        elsif result.kind_of?(Array)
          result = result.first
        end
      end
      respond_to do |format|
        format.html     { render :text=>result }
        format.textile  { render :text=> RedCloth.new(result, [:sanitize_html]).to_html  }
      end
    else
      redirect_to catalog_path(params[:id])
    end
  end

  # Uses the update_indexed_attributes method provided by ActiveFedora::Base
  # This should behave pretty much like the ActiveRecord update_indexed_attributes method
  # For more information, see the ActiveFedora docs.
  # 
  # @example Appends a new "subject" value of "My Topic" to on the descMetadata datastream in in the _PID_ document.
  #   put :update, :id=>"_PID_", "asset"=>{"descMetadata"=>{"subject"=>{"-1"=>"My Topic"}}
  # @example Sets the 1st and 2nd "medium" values on the descMetadata datastream in the _PID_ document, overwriting any existing values.
  #   put :update, :id=>"_PID_", "asset"=>{"descMetadata"=>{"medium"=>{"0"=>"Paper Document", "1"=>"Image"}}
  def update
    logger.debug("attributes submitted: #{@sanitized_params.inspect}")
         
    @response = update_document(@document, @sanitized_params)
   
    @document.save
    flash[:notice] = "Your changes have been saved."
    
    #logger.debug("returning #{@response.inspect}")
    
    respond_to do |want| 
      want.html {
        redirect_to next_step(params[:id])
      }
      want.js {
        render :json=> tidy_response_from_update(@response)  
      }
      want.textile {
        if @response.kind_of?(Hash)
          textile_response = tidy_response_from_update(@response).values.first
        end
        render :text=> RedCloth.new(textile_response, [:sanitize_html]).to_html
      }
    end
  end
  
  def new
    af_model = retrieve_af_model(params[:content_type])
    raise "Can't find a model for #{params[:content_type]}" unless af_model
    @asset = af_model.new
    apply_depositor_metadata(@asset)
    set_collection_type(@asset, params[:content_type])
    @asset.save
    model_display_name = af_model.to_s.camelize.scan(/[A-Z][^A-Z]*/).join(" ")
    msg = "Created a #{model_display_name} with pid #{@asset.pid}. Now it's ready to be edited."
    flash[:notice]= msg
    session[:scripts] = params[:combined] == "true"

    redirect_to edit_catalog_path(@asset.pid, :new_asset=>true)
  end
  
  def destroy
    af = ActiveFedora::Base.find(params[:id], :cast=>true)
    assets = af.destroy_child_assets
    af.delete
    msg = "Deleted #{params[:id]}"
    msg.concat(" and associated file_asset(s): #{assets.join(", ")}") unless assets.empty?
    flash[:notice]= msg
    redirect_to catalog_index_path()
  end

  
  # This is a method to simply remove the item from SOLR but keep the object in fedora. 
  alias_method :withdraw, :destroy
  
  protected

  def check_embargo_date_format
    if params.keys.include? [:embargo, :embargo_release_date]
      em_date = params[[:embargo, :embargo_release_date]]["0"]
      unless em_date.blank?
        begin 
          !Date.parse(em_date)
        rescue
          params[[:embargo,:embargo_release_date]]["0"] = ""
          raise "Unacceptable date format"
        end
      end
    end
  end  

  
  def mods_assets_update_validation
    desc_metadata = params[:asset][:descMetadata]
    rights_metadata = params[:asset][:rightsMetadata]
    if !rights_metadata.nil? and rights_metadata.has_key?(:embargo_embargo_release_date)
      unless rights_metadata[:embargo_embargo_release_date]["0"].blank?
        begin
          parsed_date = Date.parse(rights_metadata[:embargo_embargo_release_date]["0"]).to_s
          params[:asset][:rightsMetadata][:embargo_embargo_release_date]["0"] = parsed_date
        rescue
          flash[:error] = "You must enter a valid release date."
          return false
        end
      end
    end
    
    if !desc_metadata.nil? and desc_metadata.has_key?(:title_info_main_title) and desc_metadata.has_key?(:journal_0_title_info_main_title)
      if desc_metadata[:title_info_main_title]["0"].blank? or desc_metadata[:journal_0_title_info_main_title]["0"].blank?
        flash[:error] = "The title fields are required."
        return false
      end
    end
    
    return true
  end
end
