class Api::V1::Accounts::CustomerKeysController < Api::V1::Accounts::CustomAttributeDefinitionsController
  def index
    additional_attributes = additional_custom_attributes
    filtered_attributes = map_custom_attributes(@custom_attribute_definitions)
    filtered_attributes += additional_attributes
    render json: { data: filtered_attributes }
  end

  private

  def map_custom_attributes(objects)
    objects.map do |object|
      {
        'DisplayName': object['attribute_display_name'],
        'type': object['attribute_display_type'],
        'keyName': object['attribute_key']
      }
    end
  end

  def additional_custom_attributes
    [
      {
        DisplayName: 'Name',
        keyName: 'name',
        type: 'text'
      },
      {
        DisplayName: 'Email',
        keyName: 'email',
        type: 'text'
      },
      {
        DisplayName: 'Phone Number',
        keyName: 'phone_number',
        type: 'text'
      }
    ]
  end
end
