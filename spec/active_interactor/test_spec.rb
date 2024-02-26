require 'spec_helper'

class TestDeferredInteractor < ActiveInteractor::Base # DeferredInteractor
  def perform
    context.fail! 'Error'
  end
end

class TestFailureNested < ActiveInteractor::Organizer::Base
  organize do
    add TestDeferredInteractor
  end
end

class TestFailureRoot < ActiveInteractor::Organizer::Base
  organize do
    add TestFailureNested
  end
end

RSpec.describe TestFailureRoot do
  it 'fails' do
    result = TestFailureRoot.perform
    expect(result).to be_failure
    expect(result.error).to eq('Error')
  end
end
