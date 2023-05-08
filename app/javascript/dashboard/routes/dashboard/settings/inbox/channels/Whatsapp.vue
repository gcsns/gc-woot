<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
    />
    <div class="medium-8 columns">
      <label>
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.LABEL') }}
        <select v-model="provider">
          <option value="whatsapp_cloud">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD') }}
          </option>
          <option value="twilio">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO') }}
          </option>
          <option value="360dialog">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.360_DIALOG') }}
          </option>
          <option value="value_first">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.VALUE_FIRST') }}
          </option>
        </select>
      </label>
    </div>

    <twilio v-if="provider === 'twilio'" type="whatsapp" />
    <three-sixty-dialog-whatsapp v-else-if="provider === '360dialog'" />
    <value-first-whats-app v-else-if="provider === 'value_first'" />
    <cloud-whatsapp v-else />
  </div>
</template>

<script>
import PageHeader from '../../SettingsSubPageHeader';
import Twilio from './Twilio';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp';
import CloudWhatsapp from './CloudWhatsapp';
import ValueFirstWhatsApp from './ValueFirstWhatsApp.vue';

export default {
  components: {
    PageHeader,
    Twilio,
    ThreeSixtyDialogWhatsapp,
    CloudWhatsapp,
    ValueFirstWhatsApp,
  },
  data() {
    return {
      provider: 'whatsapp_cloud',
    };
  },
};
</script>
