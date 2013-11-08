require 'spec_helper'

describe Lumber::PreventRailsOverride do

  it "should prevent cattr_accessor for :logger" do
    new_class('Foo1')
    Foo1.send(:include, Lumber::PreventRailsOverride)
    Foo1.class_eval do
      cattr_accessor :logger
    end
    defined?(Foo1.logger).should be_false
  end

  it "should allow cattr_accessor for attrs other than :logger" do
    new_class('Foo1')
    Foo1.send(:include, Lumber::PreventRailsOverride)
    Foo1.class_eval do
      cattr_accessor :foo
    end
    defined?(Foo1.foo).should be_true
  end

end
