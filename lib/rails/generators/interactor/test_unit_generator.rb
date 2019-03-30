# frozen_string_literal: true

require_relative '../active_interactor'

module Interactor
  module Generators
    class TestUnitGenerator < ActiveInteractor::Generators::NamedBase
      desc 'Generate an interactor unit test'

      def create_test
        template 'test_unit.erb', File.join('test', 'interactors', class_path, "#{file_name}_test.rb")
      end
    end
  end
end