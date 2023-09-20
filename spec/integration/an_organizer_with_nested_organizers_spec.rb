# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'An organizer with a nested organizer with after callbacks deferred', type: :integration do
  let!(:test_interactor_1) do
    build_interactor('TestInteractor1') do
      before_perform do
        context.steps << 'before_perform_1a'
      end

      before_perform do
        context.steps << 'before_perform_1b'
      end

      after_perform do
        context.steps << 'after_perform_1a'
      end

      after_perform do
        context.steps << 'after_perform_1b'
      end

      around_perform :around_perform_a
      def around_perform_a
        context.steps << 'around_perform_1a_start'
        yield
        context.steps << 'around_perform_1a_end'
      end

      around_perform :around_perform_b
      def around_perform_b
        context.steps << 'around_perform_1b_start'
        yield
        context.steps << 'around_perform_1b_end'
      end

      def perform
        context.steps << 'perform_1'
      end
    end
  end

  let!(:test_interactor_2) do
    build_interactor('TestInteractor2') do
      before_perform do
        context.steps << 'before_perform_2a'
      end

      before_perform do
        context.steps << 'before_perform_2b'
      end

      after_perform do
        context.steps << 'after_perform_2a'
      end

      after_perform do
        context.steps << 'after_perform_2b'
      end

      around_perform :around_perform_a
      def around_perform_a
        context.steps << 'around_perform_2a_start'
        yield
        context.steps << 'around_perform_2a_end'
      end

      around_perform :around_perform_b
      def around_perform_b
        context.steps << 'around_perform_2b_start'
        yield
        context.steps << 'around_perform_2b_end'
      end

      def perform
        context.steps << 'perform_2'
      end
    end
  end

  let!(:test_interactor_3) do
    build_interactor('TestInteractor3') do
      before_perform do
        context.steps << 'before_perform_3a'
      end

      before_perform do
        context.steps << 'before_perform_3b'
      end

      after_perform do
        context.steps << 'after_perform_3a'
      end

      after_perform do
        context.steps << 'after_perform_3b'
      end

      around_perform :around_perform_a
      def around_perform_a
        context.steps << 'around_perform_3a_start'
        yield
        context.steps << 'around_perform_3a_end'
      end

      around_perform :around_perform_b
      def around_perform_b
        context.steps << 'around_perform_3b_start'
        yield
        context.steps << 'around_perform_3b_end'
      end

      def perform
        context.steps << 'perform_3'
      end
    end
  end

  let!(:test_interactor_4) do
    build_interactor('TestInteractor4') do
      before_perform do
        context.steps << 'before_perform_4a'
      end

      before_perform do
        context.steps << 'before_perform_4b'
      end

      after_perform do
        context.steps << 'after_perform_4a'
      end

      after_perform do
        context.steps << 'after_perform_4b'
      end

      around_perform :around_perform_a
      def around_perform_a
        context.steps << 'around_perform_4a_start'
        yield
        context.steps << 'around_perform_4a_end'
      end

      around_perform :around_perform_b
      def around_perform_b
        context.steps << 'around_perform_4b_start'
        yield
        context.steps << 'around_perform_4b_end'
      end

      def perform
        context.steps << 'perform_4'
      end
    end
  end

  let!(:test_organizer_inner) do
    build_organizer('TestOrganizerInner') do
      after_perform do
        context.steps << 'after_perform_organizer_inner_a'
      end

      after_perform do
        context.steps << 'after_perform_organizer_inner_b'
      end

      organize TestInteractor3
    end
  end

  let!(:test_organizer_middle) do
    build_organizer('TestOrganizerMiddle') do
      after_perform do
        context.steps << 'after_perform_organizer_middle_a'
      end

      after_perform do
        context.steps << 'after_perform_organizer_middle_b'
      end

      organize TestOrganizerInner, TestInteractor4
    end
  end

  let(:test_organizer_outer) do
    build_organizer('TestOrganizerOuter') do
      before_perform do
        context.steps = []
      end

      after_perform do
        context.steps << 'after_perform_organizer_outer_a'
      end

      after_perform do
        context.steps << 'after_perform_organizer_outer_b'
      end

      organize TestInteractor1, TestInteractor2, TestOrganizerMiddle
    end
  end

  describe '.context_class' do
    subject { test_organizer_outer.context_class }

    it { is_expected.to eq TestOrganizerOuter::Context }
    it { is_expected.to be < ActiveInteractor::Context::Base }
  end

  describe '.perform' do
    subject { test_organizer_outer.perform }

    it { is_expected.to be_a test_organizer_outer.context_class }
    it { is_expected.to be_successful }
    it { is_expected.to have_attributes(
      steps: [
        # Interactor 1
        'before_perform_1a',
        'before_perform_1b',
        'around_perform_1a_start',
        'around_perform_1b_start',
        'perform_1',
        'around_perform_1b_end',
        'around_perform_1a_end',
        'after_perform_1b',
        'after_perform_1a',

        # Interactor 2
        'before_perform_2a',
        'before_perform_2b',
        'around_perform_2a_start',
        'around_perform_2b_start',
        'perform_2',
        'around_perform_2b_end',
        'around_perform_2a_end',
        'after_perform_2b',
        'after_perform_2a',

        # Interactor 3
        'before_perform_3a',
        'before_perform_3b',
        'around_perform_3a_start',
        'around_perform_3b_start',
        'perform_3',
        'around_perform_3b_end',
        'around_perform_3a_end',
        'after_perform_3b',
        'after_perform_3a',

        # Organizer Inner
        'after_perform_organizer_inner_b',
        'after_perform_organizer_inner_a',

        # Interactor 4
        'before_perform_4a',
        'before_perform_4b',
        'around_perform_4a_start',
        'around_perform_4b_start',
        'perform_4',
        'around_perform_4b_end',
        'around_perform_4a_end',
        'after_perform_4b',
        'after_perform_4a',

        # Organizer Middle
        'after_perform_organizer_middle_b',
        'after_perform_organizer_middle_a',

        # Organizer Outer
        'after_perform_organizer_outer_b',
        'after_perform_organizer_outer_a',
      ]
    ) }
  end
end
