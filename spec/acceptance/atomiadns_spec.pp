require 'spec_helper_acceptance'

describe 'atomia::atomiadns' do
  let(:manifest) {
    <<-EOS
      class {'atomia::atomia_database':
        atomia_password  => 'password',
      }
    EOS
  }

  it 'should run without errors' do
    result = apply_manifest(manifest)
    expect(@result.exit_code).to_not be 1
  end

end
