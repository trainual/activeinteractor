# frozen_string_literal: true

module ActiveInteractor
  module Organizer
    # @author Matt Jonas <matt.jonas@gmail.com>
    # @since 1.0.0
    class Transaction < ActiveInteractor::Organizer::Base
      around_all_perform do
        ActiveRecord::Base.transaction do
          yield 
          raise ActiveRecord::Rollback if failure?
        end
      end
    end
  end
end
