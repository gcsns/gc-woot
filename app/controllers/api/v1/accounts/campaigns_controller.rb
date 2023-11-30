class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create]
  before_action :parse_audience, only: [:create]
  before_action :check_authorization

  def index
    @campaigns = Current.account.campaigns
  end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params)
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  def show; end

  def update
    @campaign.update!(campaign_params)
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :trigger_only_during_business_hours, :inbox_id, :sender_id,
                                     :scheduled_at, audience: [], trigger_rules: {}, template: {})
  end

  def parse_audience
    return unless params[:audience_type] && params[:audience_type] == 'contacts'

    time = Time.now.to_i
    contact_ids = params[:audience]
    contact_ids.each do |contact_id|
      contact = Current.account.contacts.find(contact_id)
      contact.add_labels([time.to_s])
    end
    params[:campaign][:audience] = [time.to_s]
  end
end
