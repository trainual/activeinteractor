# frozen_string_literal: true

module ActiveInteractor
  module Organizer
    # A collection of {InteractorInterface}
    #
    # @api private
    # @author Aaron Allen <hello@aaronmallen.me>
    # @since 1.0.0
    #
    # @!attribute [r] collection
    #  An array of {InteractorInterface}
    #
    #  @return [Array<InteractorInterface>] the {InteractorInterface} collection
    class InteractorInterfaceCollection
      attr_reader :collection

      # @!method map(&block)
      #  Invokes the given block once for each element of {#collection}.
      #  @return [Array] a new array containing the values returned by the block.
      delegate :map, to: :collection

      # Initialize a new instance of {InteractorInterfaceCollection}
      # @return [InteractorInterfaceCollection] a new instance of {InteractorInterfaceCollection}
      def initialize
        @collection = []
      end

      # Add an {InteractorInterface} to the {#collection}
      #
      # @param interactor_class [Const, Symbol, String] an {ActiveInteractor::Base interactor} class
      # @param filters [Hash{Symbol=> Proc, Symbol}] conditional options for the {ActiveInteractor::Base interactor}
      #  class
      # @option filters [Proc, Symbol] :if only call the {ActiveInteractor::Base interactor}
      #  {Interactor::Perform::ClassMethods#perform .perform} if `Proc` or `method` returns `true`
      # @option filters [Proc, Symbol] :unless only call the {ActiveInteractor::Base interactor}
      #  {Interactor::Perform::ClassMethods#perform .perform} if `Proc` or `method` returns `false` or `nil`
      # @return [self] the {InteractorInterfaceCollection} instance
      def add(interactor_class, filters = {})
        interface = ActiveInteractor::Organizer::InteractorInterface.new(interactor_class, filters)
        collection << interface if interface.interactor_class
        self
      end

      # Add multiple {InteractorInterface} to the {#collection}
      #
      # @param interactor_classes [Array<Const, Symbol, String>] the {ActiveInteractor::Base interactor} classes
      # @return [self] the {InteractorInterfaceCollection} instance
      def concat(interactor_classes)
        interactor_classes.flatten.each { |interactor_class| add(interactor_class) }
        self
      end

      # Calls the given block once for each element in {#collection}, passing that element as a parameter.
      # @return [self] the {InteractorInterfaceCollection} instance
      def each(&block)
        collection.each(&block) if block
        self
      end

      # Executes after_perform callbacks that have been deferred on each organized interactor. Nested
      # {Base organizers} are walked depth first, and the filters on each {InteractorInterface} are evaluated
      # against an instance of the {Base organizer} that organized it.
      #
      # @param context [Class] an instance of {Context::Base context} to run the callbacks against and merge the
      #  results into
      # @param organizer [Class] the {Base organizer} instance that owns this collection
      # @return [Class] the {Context::Base context} instance
      def execute_deferred_after_perform_callbacks(context, organizer)
        each do |interface|
          next unless interface.conditionals_met?(organizer)

          execute_deferred_after_perform_callbacks_on_nested_organizer(interface, context) if interface.organizer?

          result = interface.execute_deferred_after_perform_callbacks(context, organizer)
          context.merge!(result) if result
        end
        context
      end

      private

      def execute_deferred_after_perform_callbacks_on_nested_organizer(interface, context)
        nested_organizer = interface.interactor_class.new(context)
        interface.interactor_class.organized.execute_deferred_after_perform_callbacks(context, nested_organizer)
      end
    end
  end
end
