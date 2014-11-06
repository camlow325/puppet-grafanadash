require 'spec_helper'
describe 'grafanadash::dev' do

  context 'with defaults for all parameters' do
    it { should contain_class('grafanadash::dev') }
  end
end
