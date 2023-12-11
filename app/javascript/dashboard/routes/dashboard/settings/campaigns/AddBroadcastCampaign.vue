<template>
  <div class="column content-box">
    <div v-if="showFirstComponent">
      <woot-modal-header
        :header-title="$t('CAMPAIGN.ADD_BROADCAST.TITLE')"
        :header-content="$t('CAMPAIGN.ADD_BROADCAST.DESC')"
      />

      <form class="row" @submit.prevent="addCampaign">
        <div class="medium-12 columns">
          <woot-input
            v-model="title"
            :label="$t('CAMPAIGN.ADD_BROADCAST.FORM.TITLE.LABEL')"
            type="text"
            :class="{ error: $v.title.$error }"
            :error="$v.title.$error ? $t('CAMPAIGN.ADD.FORM.TITLE.ERROR') : ''"
            :placeholder="$t('CAMPAIGN.ADD.FORM.TITLE.PLACEHOLDER')"
            @blur="$v.title.$touch"
          />

          <label class="message-type-heading">
            {{ $t('CAMPAIGN.ADD_BROADCAST.FORM.MESSAGE.LABEL') }}
          </label>
          <div class="message-type">
            <label>
              <input
                type="radio"
                v-model="messageType"
                value="preApproved"
                name="messageType"
              />
              {{ $t('CAMPAIGN.ADD_BROADCAST.FORM.MESSAGE.MESSAGE_TYPE_1') }}
            </label>

            <label>
              <input
                type="radio"
                v-model="messageType"
                value="regular"
                name="messageType"
              />
              {{ $t('CAMPAIGN.ADD_BROADCAST.FORM.MESSAGE.MESSAGE_TYPE_2') }}
            </label>
          </div>

          <label :class="{ error: $v.selectedInbox.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.INBOX.LABEL') }}
            <select v-model="selectedInbox" @change="onChangeInbox($event)">
              <option v-for="item in inboxes" :key="item.name" :value="item.id">
                {{ item.name }}
              </option>
            </select>
            <span v-if="$v.selectedInbox.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.INBOX.ERROR') }}
            </span>
          </label>

          <label>
            {{ $t('CAMPAIGN.ADD_BROADCAST.FORM.AUDIENCE.AUDIENCE_TYPE') }}
            <select v-model="selectedAudienceType">
              <option value="labels">{{ $t('Label') }}</option>
              <option value="contacts">{{ $t('Contact') }}</option>
              <option value="csv">{{ $t('CSV') }}</option>
            </select>
          </label>

          <div class="medium-12 columns" v-if="selectedAudienceType === 'csv'">
            <label>
              <span>{{ $t('IMPORT_CONTACTS.FORM.LABEL') }}</span>
              <input
                id="file"
                ref="file"
                type="file"
                accept="text/csv"
                required
                @change="uploadAttachment"
              />
            </label>
          </div>

          <label
            class="multiselect-wrap--small"
            :class="{ error: $v.selectedAudience.$error }"
            v-else
          >
            {{ $t('CAMPAIGN.ADD.FORM.AUDIENCE.LABEL') }}
            <multiselect
              v-if="selectedAudienceType === 'labels'"
              v-model="selectedAudience"
              :options="computedAudienceOptions"
              track-by="id"
              label="title"
              :multiple="true"
              :close-on-select="false"
              :clear-on-select="false"
              :hide-selected="true"
              :placeholder="$t('CAMPAIGN.ADD.FORM.AUDIENCE.PLACEHOLDER')"
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
              @blur="$v.selectedAudience.$touch"
              @select="onSelectOption"
            />

            <multiselect
              v-else
              v-model="selectedAudience"
              :options="computedAudienceOptions"
              track-by="id"
              label="name"
              :multiple="true"
              :close-on-select="false"
              :clear-on-select="false"
              :hide-selected="true"
              :placeholder="$t('CAMPAIGN.ADD.FORM.AUDIENCE.PLACEHOLDER')"
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
              @blur="$v.selectedAudience.$touch"
              @select="onSelectOption"
            />

            <span v-if="$v.selectedAudience.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.AUDIENCE.ERROR') }}
            </span>
          </label>

          <label>
            {{ $t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.LABEL') }}
            <woot-date-time-picker
              :value="scheduledAt"
              :confirm-text="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.CONFIRM')"
              :placeholder="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.PLACEHOLDER')"
              @change="onChange"
            />
          </label>
        </div>

        <div v-if="showNextComponent">
          <!-- Render your next component here -->
          <add-campaign />
        </div>
        <div class="modal-footer">
          <woot-button
            :is-loading="uiFlags.isCreating"
            @click="handleButtonClick"
          >
            {{ $t('CAMPAIGN.ADD_BROADCAST.NEXT_BUTTON_TEXT') }}
          </woot-button>
        </div>
      </form>
    </div>
    <div v-else>
      <template-campaign
        @prevButtonClick="onPrevButtonClick"
        :audienceType="selectedAudienceType"
        :audience="selectedAudience"
        :campaignName="title"
        :scheduledTime="scheduledAt"
        :selectedInboxId="selectedInbox"
        :csvAudience="csvAudience"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { required } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import campaignMixin from 'shared/mixins/campaignMixin';
import WootDateTimePicker from 'dashboard/components/ui/DateTimePicker.vue';
import { CAMPAIGNS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import AddCampaign from './AddCampaign';
import TemplateCampaign from './TemplateCampaign';

export default {
  components: {
    WootDateTimePicker,
    AddCampaign,
    TemplateCampaign,
  },
  mixins: [alertMixin, campaignMixin],
  data() {
    return {
      title: '',
      message: '',
      selectedSender: 0,
      selectedInbox: null,
      endPoint: '',
      timeOnPage: 10,
      show: true,
      enabled: true,
      triggerOnlyDuringBusinessHours: false,
      scheduledAt: null,
      selectedAudience: [],
      senderList: [],
      messageType: this.$t(
        'CAMPAIGN.ADD_BROADCAST.FORM.MESSAGE.MESSAGE_TYPE_1'
      ),
      showNextComponent: false,
      showFirstComponent: true,
      audienceType: '', // Initialize with the appropriate value
      audience: [],
      selectedAudienceType: '',

      selectedInboxId: 0,
    };
  },

  validations() {
    const commonValidations = {
      title: {
        required,
      },
      message: {
        required,
      },
      selectedInbox: {
        required,
      },
    };
    return {
      ...commonValidations,
      selectedAudience: {
        isEmpty() {
          return !!this.selectedAudience.length;
        },
      },
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'campaigns/getUIFlags',
      audienceList: 'labels/getLabels',
      contactList: 'contacts/getContacts',
      inboxes: 'inboxes/getInboxes',
    }),
    filteredInboxes() {
      return this.inboxes.filter(
        inbox => inbox.channel_type === 'Channel::Whatsapp'
      );
    },
    computedAudienceOptions() {
      if (this.selectedAudienceType === 'labels') {
        return this.audienceList;
      } else if (this.selectedAudienceType === 'contacts') {
        return this.contactList;
      } else {
        // handle other types (Csv, etc.) if needed
        return [];
      }
    },

    sendersAndBotList() {
      return [
        {
          id: 0,
          name: 'Bot',
        },
        ...this.senderList,
        {
          prevTemplateData: {
            selectedTemplateName: '',
            inputValues: [],
            // Add other relevant data properties
          },
        },
      ];
    },
  },
  watch: {
    selectedAudienceType(newValue, oldValue) {
      // Reset selectedAudience if the audience type changes
      if (newValue !== oldValue) {
        this.selectedAudience = [];
      }
    },
  },
  mounted() {
    this.$track(CAMPAIGNS_EVENTS.OPEN_NEW_CAMPAIGN_MODAL, {
      type: this.campaignType,
    });
    this.messageType = 'regular';
    this.fetchContacts();
    this.filteredInboxes;
  },
  methods: {
    onSelectOption() {
      // Your implementation here
    },
    fetchContacts() {
      this.$store.dispatch('contacts/get');
    },

    onClose() {
      this.$emit('on-close');
    },
    onChange(value) {
      this.scheduledAt = value;
    },

    async onChangeInbox() {
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.selectedInbox,
        });
        const {
          data: { payload: inboxMembers },
        } = response;
        this.senderList = inboxMembers;
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
    handleButtonClick() {
      // This function will be called when the "Next" button is clicked

      this.showFirstComponent = false;
      this.$emit('nextButtonClick', {
        selectedTemplateName: this.selectedTemplateName,
        inputValues: this.inputValues,
        // Add other relevant data properties
      });
    },
    onPrevButtonClick(data) {
      // Update the component's data with the received values
      this.prevTemplateData = { ...data };

      // Show the first component again
      this.showFirstComponent = true;
    },
    getCampaignDetails() {
      let campaignDetails = null;

      const audience = this.selectedAudience.map(item => {
        return {
          id: item.id,
          type: 'Label',
        };
      });
      campaignDetails = {
        title: this.title,
        message: this.message,
        inbox_id: this.selectedInbox,
        scheduled_at: this.scheduledAt,
        audience,
      };

      return campaignDetails;
    },
    async uploadAttachment(event) {
      const file = event.target.files[0];
      const formData = new FormData();
      formData.append('import_file', file, file.name);
      const response =  await this.$store.dispatch(
        'contacts/verifyContacts',
        formData
      );
      this.csvAudience = [response.blob_key];
     
    },
    async addCampaign() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        const campaignDetails = this.getCampaignDetails();
        await this.$store.dispatch('campaigns/create', campaignDetails);

        // tracking this here instead of the store to track the type of campaign
        this.$track(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
          type: this.campaignType,
        });

        this.showAlert(this.$t('CAMPAIGN.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
  },
};
</script>
<style lang="scss" scoped>
::v-deep .ProseMirror-woot-style {
  height: 8rem;
}

.message-type {
  margin-top: 10px;
}

.message-type label {
  margin-right: 15px;
}

.modal-footer {
  align-self: flex-end;
  margin-top: 10px;
}
</style>
