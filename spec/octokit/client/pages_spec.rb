require 'helper'
require 'pry'

describe Octokit::Client::Pages do

  before do
    Octokit.reset!
    @client = oauth_client
    @pages_repo =  "#{test_github_login}/#{test_github_login}.github.io"
  end

  # These tests require some manual setup in your test repository,
  # ensure it has pages site enabled and setup.
  describe ".pages", :vcr do
    it "lists page information" do
      pages = @client.pages(@pages_repo)
      expect(pages).not_to be_nil
      assert_requested :get, github_url("/repos/#{@pages_repo}/pages")
    end
  end # .pages

  describe ".list_pages_builds", :vcr do
    it "lists information about all the page builds" do
      builds = @client.pages_builds(@pages_repo)
      expect(builds).to be_kind_of Array
      latest_build = builds.first
      expect(latest_build.status).to eq("built")
      assert_requested :get, github_url("/repos/#{@pages_repo}/pages/builds")
    end
  end # .list_pages_builds

  context "with build", :vcr do
      before do
        @latest_build = @client.latest_pages_build(@pages_repo)
      end

      describe ".latest_pages_build", :vcr do
        it "lists information about the latest page build" do
          expect(@latest_build.status).to eq("built")
          assert_requested :get, github_url("/repos/#{@pages_repo}/pages/builds/latest")
        end
      end # .latest_pages_build

      describe ".pages_build", :vcr do
        # uses .latest_pages_build to grab a build id
        it "lists a specific page build" do
          build_id = @latest_build.url.split("/").last
          build = @client.pages_build(@pages_repo, build_id)
          expect(build.status).not_to be_nil
          assert_requested :get, github_url("/repos/#{@pages_repo}/pages/builds/#{build_id}")
        end
      end # .pages_build
  end

  describe ".request_page_build", :vcr do
    it "requests a build for the latest revision" do
      request = @client.request_page_build(@pages_repo)
      expect(request.status).not_to be_nil
      assert_requested :post, github_url("/repos/#{@pages_repo}/pages/builds")
    end
  end # .request_page_build

  describe ".update_pages_site", :vcr do
    it "returns true with successful pages update" do
       response = @client.update_pages_site(@pages_repo, cname: "octopup.blog")
       response = @client.update_pages_site(@pages_repo, cname: nil)
       expect(response).to be_truthy
       assert_requested :put, github_url("/repos/#{@pages_repo}/pages"), :times => 2
    end
  end # .update_pages_site

  describe ".delete_pages_site", :vcr do
    it "returns true with successful pages deletion" do
       response = @client.disable_pages_site(@pages_repo, accept: preview_header)
       expect(response).to be_truthy
       assert_requested :delete, github_url("/repos/#{@pages_repo}/pages")
    end
  end # .delete_pages_site

  private

  def preview_header
    Octokit::Preview::PREVIEW_TYPES[:pages_site]
  end
end
