require 'spec_helper'

describe ProjectAutoDevops do
  set(:project) { build(:project) }

  it { is_expected.to belong_to(:project) }

  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }

  describe 'validations' do
    context 'when enabled' do
      it 'does not allow a blank hostname' do
        auto_devops = build(:project_auto_devops, enabled: false, domain: '')

        expect(auto_devops).to be_valid
      end
    end

    context 'when disabled' do
      it 'allows a blank hostname' do
        auto_devops = build(:project_auto_devops, enabled: true, domain: '')

        expect(auto_devops).not_to be_valid
      end
    end
  end

  describe 'variables' do
    let(:auto_devops) { build_stubbed(:project_auto_devops, project: project, domain: domain) }

    context 'when domain is defined' do
      let(:domain) { 'example.com' }

      it 'returns AUTO_DEVOPS_DOMAIN' do
        expect(auto_devops.variables).to include(
          { key: 'AUTO_DEVOPS_DOMAIN', value: 'example.com', public: true })
      end
    end
  end
end
