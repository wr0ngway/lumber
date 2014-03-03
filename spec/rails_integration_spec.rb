require 'spec_helper'
require 'active_support/time'

describe "Rails Integration" do

  class RailsRunner

    def initialize(rails_root)
      Bundler.with_clean_env do
        @io = open("|#{rails_root}/bin/rails runner 'STDOUT.sync=STDERR.sync=true; loop { begin; puts eval gets.to_s; rescue => e; p e; end }'", "w+")
        @pid = $?.pid
      end
    end

    def execute(cmd)
      @io.puts(cmd)
      @io.gets.to_s.strip
    end
  end

  before(:all) do
    project_dir = File.expand_path("../..", __FILE__)
    spec_dir = "#{project_dir}/spec"

    @rails_root = "/tmp/lumber_test_rails_integration"
    if ! File.exist?(@rails_root) || File.mtime(@rails_root) < 1.day.ago
      FileUtils.rm_rf(@rails_root)
      out = `cd #{project_dir} && bundle exec rails new #{@rails_root} -m #{spec_dir}/lumber_rails_template.rb`
      fail(out) unless $?.success?
    end

    @runner = RailsRunner.new(@rails_root)
  end

  after(:all) do
    @runner.execute('exit!')
    #FileUtils.rm_rf(@rails_root)
  end

  it "has a rails logger" do
    @runner.execute("Rails.logger.class").should == "Log4r::Logger"
    @runner.execute("Rails.logger.fullname").should == "rails"
  end

  it "has a rails logger for models" do
    @runner.execute("User.logger.class").should == "Log4r::Logger"
    @runner.execute("User.logger.fullname").should == "rails::models::User"
  end

  it "has a rails logger for mailers" do
    @runner.execute("UserMailer.logger.class").should == "Log4r::Logger"
    @runner.execute("UserMailer.logger.fullname").should == "rails::mailers::UserMailer"
  end

  it "has a rails logger for controllers" do
    @runner.execute("UsersController.logger.class").should == "Log4r::Logger"
    @runner.execute("UsersController.logger.fullname").should == "rails::controllers::UsersController"
  end

end

