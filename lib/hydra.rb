require "blacklight"
require 'active-fedora'
require 'cancan'

# Hydra libraries
module Hydra
  extend Blacklight::GlobalConfigurable
  # Naomi sez:  Autoload is not thread-safe and will be removed in ruby 3.0
  #   http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/41149
  extend ActiveSupport::Autoload
  autoload :AccessControlsEvaluation
  autoload :AccessControlsEnforcement
  autoload :Assets
  autoload :Catalog
  autoload :Controller
  autoload :FileAssets
  autoload :GenericContent
  autoload :GenericImage
  autoload :GenericUserAttributes
  autoload :ModelMixins
  autoload :RepositoryController
  autoload :SubmissionWorkflow
  autoload :SuperuserAttributes
  autoload :User
  autoload :UI
  autoload :Workflow
end

require 'hydra/assets_controller_helper'
require 'hydra/file_assets_helper'
require 'hydra/model_methods'
require 'hydra/models/file_asset'
