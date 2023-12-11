class Api::V1::Accounts::BulkContactController < Api::V1::Accounts::ContactsController
  before_action :check_authorization, except: [:verify]
  def verify
    render json: { error: I18n.t('errors.contacts.import.failed') }, status: :unprocessable_entity and return if params[:import_file].blank?

    file_blob = ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: params[:import_file].tempfile,
      filename: params[:import_file].original_filename,
      content_type: params[:import_file].content_type
    )

    rejected_contacts = parse_csv_and_build_contacts(params[:import_file])
    objects_array = rejected_contacts.map(&:to_h)
    render json: { blob_key: file_blob.key, blob_id: file_blob.id, rejected_contacts: objects_array }, status: :ok
  end

  def parse_csv_and_build_contacts(import_file)
    rejected_contacts = []
    csv = CSV.parse(import_file.read, headers: true)
    time = Time.now.to_i
    csv.each do |row|
      current_contact = build_contact(row.to_h.with_indifferent_access, Current.account, time)
      unless current_contact.valid?
        row['errors'] = current_contact.errors.full_messages.join(', ')
        rejected_contacts << row
      end
    end
    rejected_contacts
  end

  def build_contact(params, account, _time)
    contact = find_or_initialize_contact(params, account)
    contact.name = params[:name] if params[:name].present?
    contact.additional_attributes ||= {}
    contact.additional_attributes[:company] = params[:company] if params[:company].present?
    contact.additional_attributes[:city] = params[:city] if params[:city].present?
    contact.assign_attributes(custom_attributes: contact.custom_attributes.merge(params.except(:identifier, :email, :name, :phone_number)))
    contact
  end

  def find_or_initialize_contact(params, account)
    contact = find_existing_contact(params, account)
    contact ||= account.contacts.new(params.slice(:email, :identifier, :phone_number))
    contact
  end

  def find_existing_contact(params, account)
    contact = find_contact_by_identifier(params, account)
    contact ||= find_contact_by_email(params, account)
    contact ||= find_contact_by_phone_number(params, account)

    update_contact_with_merged_attributes(params, contact) if contact.present? && contact.valid?
    contact
  end

  def find_contact_by_identifier(params, account)
    return unless params[:identifier]

    account.contacts.find_by(identifier: params[:identifier])
  end

  def find_contact_by_email(params, account)
    return unless params[:email]

    account.contacts.find_by(email: params[:email])
  end

  def find_contact_by_phone_number(params, account)
    return unless params[:phone_number]

    account.contacts.find_by(phone_number: params[:phone_number])
  end

  def update_contact_with_merged_attributes(params, contact)
    contact.email = params[:email] if params[:email].present?
    contact.phone_number = params[:phone_number] if params[:phone_number].present?
    contact.save
  end
end
