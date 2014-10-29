require 'spec_helper'
describe 'grafanadash' do

  context 'with defaults for all parameters' do
    it { should contain_class('grafanadash') }
  end
end
