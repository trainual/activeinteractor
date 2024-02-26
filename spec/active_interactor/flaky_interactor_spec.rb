# frozen_string_literal: true
require 'spec_helper'

class FlakyDeferredInteractorBase < ActiveInteractor::Base
  defer_after_callbacks_when_organized
end

class FlakyDeferredInteractor < FlakyDeferredInteractorBase
  after_perform :test_after_perform

  private

  def test_after_perform
    context.called_test_after_perform = true
  end
end

class FlakyOrganizerInteractor < ActiveInteractor::Organizer::Base
  # defer_after_callbacks_when_organized
  organize do
    add FlakyDeferredInteractor
  end
end

RSpec.describe FlakyOrganizerInteractor do
  it 'Test FlakyOrganizerInteractor' do
    result = FlakyOrganizerInteractor.perform
    expect(result).to be_success
    expect(result.called_test_after_perform).to be(true)
  end

  it 'Test FlakyDeferredInteractor' do
    result = FlakyDeferredInteractor.perform
    expect(result).to be_success
    expect(result.called_test_after_perform).to be(true)
  end
end