# This Builder will create a contact and contact inbox with specified attributes.
# If an existing identified contact exisits, it will be returned.
# for contact inbox logic it uses the contact inbox builder

class ContactInboxWithContactBuilder
  pattr_initialize [:inbox!, :contact_attributes!, :source_id, :hmac_verified]

  def perform
    find_or_create_contact_and_contact_inbox
  # in case of race conditions where contact is created by another thread
  # we will try to find the contact and create a contact inbox
  rescue ActiveRecord::RecordNotUnique
    find_or_create_contact_and_contact_inbox
  end

  def find_or_create_contact_and_contact_inbox
    @contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id) if source_id.present?
    return @contact_inbox if @contact_inbox

    ActiveRecord::Base.transaction(requires_new: true) do
      build_contact_with_contact_inbox
      update_contact_avatar(@contact) unless @contact.avatar.attached?
      @contact_inbox
    end
  end

  private

  def build_contact_with_contact_inbox
    @contact = find_contact || create_contact
    @contact_inbox = create_contact_inbox
  end

  def account
    @account ||= inbox.account
  end

  def create_contact_inbox
    ContactInboxBuilder.new(
      contact: @contact,
      inbox: @inbox,
      source_id: @source_id,
      hmac_verified: hmac_verified
    ).perform
  end

  def update_contact_avatar(contact)
    ::Avatar::AvatarFromUrlJob.perform_later(contact, contact_attributes[:avatar_url]) if contact_attributes[:avatar_url]
  end

  def create_contact
    creation_result = account.contacts.create!(
      name: contact_attributes[:name] || ::Haikunator.haikunate(1000),
      phone_number: contact_attributes[:phone_number],
      email: contact_attributes[:email],
      identifier: contact_attributes[:identifier],
      additional_attributes: contact_attributes[:additional_attributes],
      custom_attributes: contact_attributes[:custom_attributes]
    )
    create_customer_on_shopkey if contact_attributes[:store_number]
    creation_result
  end

  def find_contact
    contact = find_contact_by_identifier(contact_attributes[:identifier])
    contact ||= find_contact_by_email(contact_attributes[:email])
    contact ||= find_contact_by_phone_number(contact_attributes[:phone_number])
    contact
  end

  def find_contact_by_identifier(identifier)
    return if identifier.blank?

    account.contacts.find_by(identifier: identifier)
  end

  def find_contact_by_email(email)
    return if email.blank?

    account.contacts.find_by(email: email.downcase)
  end

  def find_contact_by_phone_number(phone_number)
    return if phone_number.blank?

    account.contacts.find_by(phone_number: phone_number)
  end

  def create_customer_on_shopkey
    store_info = HTTParty.get(
      "https://uam.shopkey.dev/api/user/phone/+#{contact_attributes[:store_number]}",
      headers: {
        'env' => 'LIVE'
      }
    )
    return unless store_info['statusCode'] === 200

    store_info = store_info['data']
    store_code = store_info['storeUrl'].split('://')
    store_code = store_code[1].split('.').first
    data = {
      custom_attributes: [
        {
          attribute_code: 'whatsapp_phone_number',
          label: contact_attributes[:phone_number],
          value: contact_attributes[:phone_number]
        },
        {
          attribute_code: 'store_view_id',
          label: "#{store_info['magentoStoreId']}",
          value: "#{store_info['magentoStoreId']}"
        }
      ],
      empId: "#{store_info['empId']}",
      firstname: contact_attributes[:name],
      lastname: '',
      magentoServerId: store_info['magentoServerId'],
      phoneNumber: contact_attributes[:phone_number],
      storeCode: store_code,
      store_id: '',
      store_view_id: store_info['magentoStoreId'],
      website_id: '0'
    }

    data['email'] = contact_attributes[:email] if contact_attributes[:email]
    contact_creation_response = HTTParty.post(
      'https://customer-onboarding.shopkey.dev/api/customer/save',
      headers: {
        'env' => 'LIVE',
        'Content-Type' => 'application/json'
      },
      body: data.to_json
    )
  end
end
