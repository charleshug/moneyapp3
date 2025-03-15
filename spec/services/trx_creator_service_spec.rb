require 'rails_helper'

RSpec.describe TrxCreatorService do
  let(:service) { TrxCreatorService.new }
  let(:budget) { create(:budget) }
  let(:account) { create(:account, budget: budget) }
  let(:vendor) { create(:vendor, budget: budget) }
  let(:category) { create(:category, budget: budget) }
  let(:subcategory) { create(:subcategory, category: category) }

  describe '#create_trx' do
    context 'with valid parameters' do
      let(:trx_params) do
        {
          account_id: account.id,
          vendor_id: vendor.id,
          date: Date.today,
          memo: 'Test transaction',
          lines_attributes: {
            '0' => {
              subcategory_form_id: subcategory.id,
              amount: '10.50',
              memo: 'Test line'
            }
          }
        }
      end

      it 'creates a transaction with the correct attributes' do
        trx = service.create_trx(budget, trx_params)

        expect(trx).to be_persisted
        expect(trx.account).to eq(account)
        expect(trx.vendor).to eq(vendor)
        expect(trx.date).to eq(Date.today)
        expect(trx.memo).to eq('Test transaction')
        expect(trx.amount).to eq(1050) # Converted to cents
      end

      it 'creates transaction lines with the correct attributes' do
        trx = service.create_trx(budget, trx_params)
        line = trx.lines.first

        expect(line).to be_persisted
        expect(line.amount).to eq(1050) # Converted to cents
        expect(line.memo).to eq('Test line')
      end

      it 'associates lines with the correct ledger' do
        trx = service.create_trx(budget, trx_params)
        line = trx.lines.first

        expect(line.ledger).to be_present
        expect(line.ledger.subcategory).to eq(subcategory)
        expect(line.ledger.date).to eq(Date.today.end_of_month)
      end

      it 'updates the account balance' do
        expect_any_instance_of(Account).to receive(:calculate_balance!)
        service.create_trx(budget, trx_params)
      end

      it 'recalculates ledgers' do
        expect(LedgerService).to receive(:recalculate_forward_ledgers).once
        service.create_trx(budget, trx_params)
      end
    end

    context 'with custom vendor text' do
      let(:trx_params) do
        {
          account_id: account.id,
          vendor_custom_text: 'New Vendor',
          date: Date.today,
          lines_attributes: {
            '0' => {
              subcategory_form_id: subcategory.id,
              amount: '10.50'
            }
          }
        }
      end

      it 'creates a new vendor if it does not exist' do
        expect {
          service.create_trx(budget, trx_params)
        }.to change { budget.vendors.count }.by(1)

        expect(budget.vendors.last.name).to eq('New Vendor')
      end

      it 'uses an existing vendor if it exists' do
        existing_vendor = create(:vendor, name: 'New Vendor', budget: budget)

        expect {
          trx = service.create_trx(budget, trx_params)
          expect(trx.vendor).to eq(existing_vendor)
        }.not_to change { budget.vendors.count }
      end
    end

    context 'with multiple lines' do
      let(:subcategory2) { create(:subcategory, category: category) }
      let(:trx_params) do
        {
          account_id: account.id,
          vendor_id: vendor.id,
          date: Date.today,
          lines_attributes: {
            '0' => {
              subcategory_form_id: subcategory.id,
              amount: '10.50'
            },
            '1' => {
              subcategory_form_id: subcategory2.id,
              amount: '5.25'
            }
          }
        }
      end

      it 'creates all lines' do
        trx = service.create_trx(budget, trx_params)

        expect(trx.lines.count).to eq(2)
        expect(trx.amount).to eq(1575) # Sum of both lines in cents
      end

      it 'creates appropriate ledgers for each line' do
        trx = service.create_trx(budget, trx_params)

        expect(trx.lines[0].ledger.subcategory).to eq(subcategory)
        expect(trx.lines[1].ledger.subcategory).to eq(subcategory2)
      end

      it 'recalculates all affected ledgers' do
        expect(LedgerService).to receive(:recalculate_forward_ledgers).twice
        service.create_trx(budget, trx_params)
      end
    end

    context 'with transaction errors' do
      let(:invalid_trx_params) do
        {
          # Missing account_id
          vendor_id: vendor.id,
          date: Date.today,
          lines_attributes: {
            '0' => {
              subcategory_form_id: subcategory.id,
              amount: '10.50'
            }
          }
        }
      end

      it 'does not create a transaction if validation fails' do
        expect {
          trx = service.create_trx(budget, invalid_trx_params)
          expect(trx).not_to be_valid
        }.not_to change(Trx, :count)
      end

      it 'rolls back the transaction if an error occurs' do
        # Define valid params for this test
        valid_params = {
          account_id: account.id,
          vendor_id: vendor.id,
          date: Date.today,
          lines_attributes: {
            '0' => {
              subcategory_form_id: subcategory.id,
              amount: '10.50'
            }
          }
        }

        # Make the Trx#save method raise an exception
        allow_any_instance_of(Trx).to receive(:save).and_raise(ActiveRecord::RecordInvalid.new(Trx.new))

        expect {
          service.create_trx(budget, valid_params)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
