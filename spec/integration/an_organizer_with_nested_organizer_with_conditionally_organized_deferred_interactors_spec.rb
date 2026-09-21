# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'An organizer with a nested organizer with conditionally organized deferred interactors',
               type: :integration do
  let!(:leaf) do
    build_interactor('TestLeaf') do
      defer_after_callbacks_when_organized

      after_perform do
        context.after_ran = true
      end

      def perform
        context.performed = true
      end
    end
  end

  shared_examples 'a nested organizer whose filters see the nested organizer' do
    describe '.perform' do
      subject { outer.perform(kind: kind) }

      context 'when the filter is satisfied' do
        let(:kind) { 'leaf' }

        it { is_expected.to be_a outer.context_class }
        it { is_expected.to be_successful }
        it { is_expected.to have_attributes(performed: true, after_ran: true) }
      end

      context 'when the filter is not satisfied' do
        let(:kind) { 'other' }

        it { is_expected.to be_a outer.context_class }
        it { is_expected.to be_successful }

        it 'is expected not to set the leaf attributes' do
          expect(subject.attributes).not_to include(:performed, :after_ran)
        end

        it 'is expected not to receive #perform on the leaf' do
          expect_any_instance_of(leaf).not_to receive(:perform)
          subject
        end
      end
    end
  end

  context 'with a Proc filter on the nested organizer child' do
    let!(:inner) do
      build_organizer('TestInner') do
        organize do
          add TestLeaf, if: -> { context.kind == 'leaf' }
        end
      end
    end

    let!(:outer) do
      build_organizer('TestOuter') do
        organize do
          add TestInner
        end
      end
    end

    include_examples 'a nested organizer whose filters see the nested organizer'
  end

  context 'with a Symbol filter on the nested organizer child' do
    let!(:inner) do
      build_organizer('TestInner') do
        organize do
          add TestLeaf, if: :leaf?
        end

        def leaf?
          context.kind == 'leaf'
        end
      end
    end

    let!(:outer) do
      build_organizer('TestOuter') do
        organize do
          add TestInner
        end
      end
    end

    include_examples 'a nested organizer whose filters see the nested organizer'
  end

  context 'with an :unless filter on the nested organizer child' do
    let!(:inner) do
      build_organizer('TestInner') do
        organize do
          add TestLeaf, unless: -> { context.kind != 'leaf' }
        end
      end
    end

    let!(:outer) do
      build_organizer('TestOuter') do
        organize do
          add TestInner
        end
      end
    end

    include_examples 'a nested organizer whose filters see the nested organizer'
  end

  context 'when the outer organizer also defers its after callbacks' do
    let!(:inner) do
      build_organizer('TestInner') do
        organize do
          add TestLeaf, if: -> { context.kind == 'leaf' }
        end
      end
    end

    let!(:outer) do
      build_organizer('TestOuter') do
        defer_after_callbacks_when_organized

        organize do
          add TestInner
        end
      end
    end

    include_examples 'a nested organizer whose filters see the nested organizer'
  end

  context 'with three levels of nesting' do
    let!(:counting_leaf) do
      build_interactor('TestCountingLeaf') do
        defer_after_callbacks_when_organized

        after_perform do
          context.after_count = (context.after_count || 0) + 1
        end

        def perform
          context.perform_count = (context.perform_count || 0) + 1
        end
      end
    end

    let!(:innermost) do
      build_organizer('TestInnermost') do
        organize do
          add TestCountingLeaf, if: -> { context.kind == 'leaf' }
        end
      end
    end

    let!(:middle) do
      build_organizer('TestMiddle') do
        organize do
          add TestInnermost, if: :nested?
        end

        def nested?
          context.nested
        end
      end
    end

    let!(:outer) do
      build_organizer('TestOuter') do
        organize do
          add TestMiddle
        end
      end
    end

    describe '.perform' do
      subject { outer.perform(kind: kind, nested: nested) }

      context 'when every filter is satisfied' do
        let(:kind) { 'leaf' }
        let(:nested) { true }

        it { is_expected.to be_successful }

        it 'is expected to perform the leaf and run its deferred after callback exactly once' do
          expect(subject).to have_attributes(perform_count: 1, after_count: 1)
        end
      end

      context 'when the innermost filter is not satisfied' do
        let(:kind) { 'other' }
        let(:nested) { true }

        it { is_expected.to be_successful }

        it 'is expected not to set the leaf attributes' do
          expect(subject.attributes).not_to include(:perform_count, :after_count)
        end
      end

      context 'when the filter on the nested organizer itself is not satisfied' do
        let(:kind) { 'leaf' }
        let(:nested) { false }

        it { is_expected.to be_successful }

        it 'is expected not to set the leaf attributes' do
          expect(subject.attributes).not_to include(:perform_count, :after_count)
        end
      end
    end
  end

  context 'with a deferring organizer nested two levels deep' do
    let!(:inner) do
      build_organizer('TestInner') do
        defer_after_callbacks_when_organized

        after_perform do
          context.inner_after_count = (context.inner_after_count || 0) + 1
        end

        organize do
          add TestLeaf, if: -> { context.kind == 'leaf' }
        end
      end
    end

    let!(:middle) do
      build_organizer('TestMiddle') do
        organize do
          add TestInner, if: -> { context.nested }
        end
      end
    end

    let!(:outer) do
      build_organizer('TestOuter') do
        organize do
          add TestMiddle
        end
      end
    end

    describe '.perform' do
      subject { outer.perform(kind: kind, nested: nested) }

      context 'when every filter is satisfied' do
        let(:kind) { 'leaf' }
        let(:nested) { true }

        it { is_expected.to be_successful }
        it { is_expected.to have_attributes(performed: true, after_ran: true, inner_after_count: 1) }
      end

      context 'when the filter on the nested organizer is not satisfied' do
        let(:kind) { 'leaf' }
        let(:nested) { false }

        it { is_expected.to be_successful }

        it 'is expected not to run the nested organizer or its children' do
          expect(subject.attributes).not_to include(:performed, :after_ran, :inner_after_count)
        end
      end
    end
  end

  context 'with a filter on a direct child of the top-level organizer' do
    let!(:outer) do
      build_organizer('TestOuter') do
        organize do
          add TestLeaf, if: -> { context.kind == 'leaf' }
        end
      end
    end

    describe '.perform' do
      subject { outer.perform(kind: kind) }

      context 'when the filter is satisfied' do
        let(:kind) { 'leaf' }

        it { is_expected.to be_successful }
        it { is_expected.to have_attributes(performed: true, after_ran: true) }
      end

      context 'when the filter is not satisfied' do
        let(:kind) { 'other' }

        it { is_expected.to be_successful }

        it 'is expected not to set the leaf attributes' do
          expect(subject.attributes).not_to include(:performed, :after_ran)
        end
      end
    end
  end
end
