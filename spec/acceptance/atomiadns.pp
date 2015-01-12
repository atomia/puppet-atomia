require 'spec_helper_acceptance'

describe 'atomiadns:' do
  it 'should run sucessfully' do
    pp <<-EOS
    class { 'atomia::profile::dns::atomiadns_master': }
    EOS
  end
end
