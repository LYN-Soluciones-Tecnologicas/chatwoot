require 'rails_helper'

RSpec.describe Conversations::InactiveDeletionJob do
  subject(:job) { described_class.perform_later(account: account) }

  let!(:account) { create(:account) }

  it 'enqueues the job on the purgable queue' do
    expect { job }.to have_enqueued_job(described_class).with(account: account).on_queue('purgable')
  end

  it 'delegates to Conversations::DeleteInactiveService' do
    service = instance_double(Conversations::DeleteInactiveService, perform: 0)
    expect(Conversations::DeleteInactiveService).to receive(:new).with(account: account).and_return(service)
    described_class.perform_now(account: account)
    expect(service).to have_received(:perform)
  end
end
