require 'spec_helper'

describe Lumber::PreventRailsOverride do

  it "should prevent cattr_accessor for :logger" do
    new_class('Foo1')
    Foo1.send(:include, Lumber::PreventRailsOverride)
    Foo1.class_eval do
      cattr_accessor :logger
    end
    Foo1.method_defined?(:logger).should be_false
    Foo1.method_defined?(:logger=).should be_false
  end

  it "should allow cattr_accessor for attrs other than :logger" do
    new_class('Foo1')
    Foo1.send(:include, Lumber::PreventRailsOverride)
    Foo1.class_eval do
      cattr_accessor :foo
    end
    Foo1.method_defined?(:foo).should be_true
    Foo1.method_defined?(:foo=).should be_true
  end

  it "should prevent mattr_accessor for :logger" do
    new_class('Foo1')
    Foo1.send(:include, Lumber::PreventRailsOverride)
    Foo1.class_eval do
      mattr_accessor :logger
    end
    Foo1.method_defined?(:logger).should be_false
    Foo1.method_defined?(:logger=).should be_false
  end

  it "should allow mattr_accessor for attrs other than :logger" do
    new_class('Foo1')
    Foo1.send(:include, Lumber::PreventRailsOverride)
    Foo1.class_eval do
      mattr_accessor :foo
    end
    Foo1.method_defined?(:foo).should be_true
    Foo1.method_defined?(:foo=).should be_true
  end

end
