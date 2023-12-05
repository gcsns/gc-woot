<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
    />
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
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
          <option value="ai_sensy">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.AI_SENSY') }}
          </option>
          <option value="gup_shup">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.GUP_SHUP') }}
          </option>
        </select>
      </label>
    </div>

    <twilio v-if="provider === 'twilio'" type="whatsapp" />
    <three-sixty-dialog-whatsapp v-else-if="provider === '360dialog'" />
    <value-first-whats-app v-else-if="provider === 'value_first'" />
    <ai-sensy-whats-app v-else-if="provider === 'ai_sensy'" />
    <gup-shup-whatsapp v-else-if="provider === 'gup_shup'" />
    <cloud-whatsapp v-else />
  </div>
</template>

<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import ValueFirstWhatsApp from './ValueFirstWhatsApp.vue';
import AiSensyWhatsApp from './AiSensyWhatsApp.vue';
import GupShupWhatsapp from './GupShupWhatsapp.vue';

export default {
  components: {
    PageHeader,
    Twilio,
    ThreeSixtyDialogWhatsapp,
    CloudWhatsapp,
    ValueFirstWhatsApp,
    AiSensyWhatsApp,
    GupShupWhatsapp,
  },
  data() {
    return {
      provider: 'whatsapp_cloud',
    };
  },
};
</script>
