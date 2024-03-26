# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'An organizer with after callbacks deferred', type: :integration do
  let!(:test_interactor_1) do
    build_interactor('TestInteractor1') do
      defer_after_callbacks_when_organized

      after_perform do
        context.steps << 'after_perform_1a'
        context.called_test_after_perform = true
      end

      after_perform do
        context.steps << 'after_perform_1b'
      end

      def perform
        context.fail! if context.should_fail
        context.steps = []
        context.steps << 'perform_1'
      end
    end
  end

  let!(:test_interactor_2) do
    build_interactor('TestInteractor2') do
      defer_after_callbacks_when_organized

      after_perform do
        context.steps << 'after_perform_2'
      end

      def perform
        context.steps << 'perform_2'
      end
    end
  end

  let!(:test_interactor_3) do
    build_interactor('TestInteractor3') do
      after_perform do
        context.steps << 'after_perform_3a'
      end

      after_perform do
        context.steps << 'after_perform_3b'
      end

      def perform
        context.steps << 'perform_3'
      end
    end
  end

  let(:interactor_class) do
    build_organizer do
      organize TestInteractor1, TestInteractor2, TestInteractor3
    end
  end
  
  let(:organizer) { interactor_class }

  include_examples 'a class with interactor methods'
  include_examples 'a class with interactor callback methods'
  include_examples 'a class with interactor context methods'
  include_examples 'a class with organizer callback methods'

  describe '.context_class' do
    subject { interactor_class.context_class }

    it { is_expected.to eq TestOrganizer::Context }
    it { is_expected.to be < ActiveInteractor::Context::Base }
  end

  describe '.perform' do
    subject { interactor_class.perform }

    it { is_expected.to be_a interactor_class.context_class }
    it { is_expected.to be_successful }
    it { is_expected.to have_attributes(
      steps: [
        'perform_1',
        'perform_2',
        'perform_3',
        'after_perform_3b',
        'after_perform_3a',
        'after_perform_1b',
        'after_perform_1a',
        'after_perform_2',
      ]
    ) }

    context 'when last interactor fails' do
      let!(:failing_interactor) do
        build_interactor('FailingInteractor') do
          def perform
            context.fail!
          end
        end
      end

      let(:interactor_class) do
        build_organizer do
          organize TestInteractor1, TestInteractor2, FailingInteractor
        end
      end

      subject { interactor_class.perform}

      it { is_expected.to have_attributes(
        steps: [
          'perform_1',
          'perform_2'
        ]
      )}
    end

    context 'when after_perform in first interactor fails' do
      let!(:failing_interactor) do
        build_interactor('FailingInteractor') do
          defer_after_callbacks_when_organized

          after_perform do
            context.fail!
          end

          def perform
            context.steps = []
            context.steps << 'perform_1'
          end
        end
      end

      let(:interactor_class) do
        build_organizer do
          organize FailingInteractor, TestInteractor2, TestInteractor3
        end
      end

      subject { interactor_class.perform}

      it { is_expected.to have_attributes(
        steps: [
          'perform_1',
          'perform_2',
          'perform_3',
          'after_perform_3b',
          'after_perform_3a',
        ]
      )}
    end

    context 'when interactor is called via organizer' do
      context 'and interactor is called individually prior' do
        it 'calls the after_perform callbacks in both cases' do
          result = test_interactor_1.perform
          expect(result).to be_success
          expect(result.called_test_after_perform).to be(true)
 
          result = organizer.perform
          expect(result).to be_success
          expect(result.called_test_after_perform).to be(true)
        end

        context 'and interactor fails when called individually' do
          it 'calls the after_perform callbacks just when organized' do
            result = test_interactor_1.perform(should_fail: true)
            expect(result).to be_failure
            expect(result.called_test_after_perform).to be_nil
  
            result = organizer.perform
            expect(result).to be_success
            expect(result.called_test_after_perform).to be(true)
          end
        end
      end

      context 'and interactor is called individually after' do
        it 'calls the after_perform callbacks in both cases' do
          result = organizer.perform
          expect(result).to be_success
          expect(result.called_test_after_perform).to be(true)

          result = test_interactor_1.perform
          expect(result).to be_success
          expect(result.called_test_after_perform).to be(true)
        end

        context 'and interactor fails when called individually' do
          it 'calls the after_perform callbacks just when organized' do
            result = organizer.perform
            expect(result).to be_success
            expect(result.called_test_after_perform).to be(true)

            result = test_interactor_1.perform(should_fail: true)
            expect(result).to be_failure
            expect(result.called_test_after_perform).to be_nil
          end
        end
      end
    end
  end
end