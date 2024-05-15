require 'json'
require 'rspec'

RSpec.shared_context('with tmpdir') do
  let(:tmpdir) { @tmpdir } # rubocop:disable RSpec/InstanceVariable

  around(:each) do |example|
    Dir.mktmpdir('rspec-provision_test') do |t|
      @tmpdir = t
      example.run
    end
  end
end

describe 'vagrant' do
  before(:each) do
    # Stub $stdin.read to return a predefined JSON string
    allow($stdin).to receive(:read).and_return({
      platform: 'generic/debian10',
      action: 'provision',
      vars: 'role: worker1',
      inventory: './spec/fixtures/litmus_inventory.yaml',
      enable_synced_folder: 'true',
      provider: 'virtualbox',
      hyperv_vswitch: 'hyperv_vswitch',
      hyperv_smb_username: 'hyperv_smb_username'
    }.to_json)
    # Load the task file after stubbing $stdin, as the task file reads from $stdin on load
    require_relative '../../tasks/vagrant'
    let(:inventory_dir) { "#{tmpdir}/spec/fixtures" }
    let(:inventory_file) { "#{inventory_dir}/litmus_inventory.yaml" }

    include_context('with tmpdir')
  end

  it 'provisions a new vagrant box when action is provision' do
    result = provision(platform, inventory_file, enable_synced_folder, provider, cpus, memory, hyperv_vswitch, hyperv_smb_username, hyperv_smb_password, box_url, password, vars)
    expect(result[:status]).to eq('ok')
    expect(result[:node]['facts']['provisioner']).to eq('vagrant')
    expect(result[:node]['facts']['platform']).to eq(platform)
    expect(result[:node]['vars']).to eq(JSON.parse(vars))
  end
end
