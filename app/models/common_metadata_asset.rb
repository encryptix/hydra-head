# Used to test default view partials;  this is a basic hydra model with no specific views
# EXAMPLE of a basic model that conforms to Hydra commonMetadata cModel and has basic MODS metadata
class CommonMetadataAsset < ActiveFedora::Base
  
  # declares a rightsMetadata datastream with type Hydra::Datastream::RightsMetadata
  #  basically, it is another expression of
  #  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::ModelMixins::CommonMetadata
  
  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
  
end

