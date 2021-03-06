require 'spec_helper'

class DummyFileAsset < ActiveFedora::Base
  def initialize(attr={})
    super(attr)
    add_relationship(:has_model, "info:fedora/afmodel:FileAsset")
  end
end

describe FileAsset do
  before(:each) do
    @file_asset = FileAsset.new
  end
  after(:each) do
    begin
    @file_asset.delete
    rescue
    end
  end
  describe "with parts" do
    before(:each) do
      @asset1 = ActiveFedora::Base.new
      @asset1.save
    end

    after(:each) do
      @asset1.delete
    end

    describe ".container_id" do    
      it "should return asset container objects via is_part_of relationships" do
        #none
        @file_asset.container_id.should be_nil
        #is_part_of
        @file_asset.container = @asset1
        @file_asset.container_id.should == @asset1.pid
      end
    end
  end

  describe ".to_solr" do
    it "should load base fields correctly if active_fedora_model is FileAsset" do
      @file_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      solr_doc = @file_asset.to_solr
      solr_doc["title_t"].should == ["testing"]
    end
    it "should load base fields for FileAsset for model_only if active_fedora_model is not FileAsset but is not child of FileAsset" do
      pending "I'm unconvinced as to the usefullness of this test. Why create as one type then reload as another? - Justin"
      @dummy_file_asset = DummyFileAsset.new
      @dummy_file_asset.save
      file_asset = FileAsset.find(@dummy_file_asset.pid)
      ENABLE_SOLR_UPDATES = false
      #it should save change to Fedora, but not solr
      file_asset.update_indexed_attributes({:title=>{0=>"testing"}})
      file_asset.save
      ENABLE_SOLR_UPDATES = true
      solr_doc = DummyFileAsset.find_by_solr(@dummy_file_asset.pid).hits.first
      solr_doc["title_t"].should be_nil
      @dummy_file_asset.update_index
      solr_doc = DummyFileAsset.find_by_solr(@dummy_file_asset.pid).hits.first
      solr_doc["title_t"].should == ["testing"]
      begin
      @dummy_file_asset.delete
      rescue
      end
    end
  end
end
