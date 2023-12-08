<template>
  <div class="column content-box">
    <woot-modal-header :header-title="$t('CAMPAIGN.ADD.TITLE')" />

    <form class="row" @submit.prevent="addCampaign">
      <!-- Left Column (Form Elements) -->
      <div class="form-container left-column">
        <div class="form-section">
          <label :class="{ error: $v.title.$error }">
            {{ $t('CAMPAIGN.ADD_BROADCAST.FORM.TEMPLATE.LABEL') }}
            <select
              v-model="selectedTemplateName"
              @change="onTemplateNameChange"
            >
              <option
                v-for="(template, index) in templateOptions"
                :key="index"
                :value="template.name"
              >
                {{ template.name }}
              </option>
            </select>
            <span v-if="$v.title.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.TITLE.ERROR') }}
            </span>
          </label>

          <div v-if="selectedTemplateName !== ''">
            <div v-if="hasParameters" class="vertical-input-container">
              <label for="parameters" class="input-label">Parameters</label>
              <div v-for="index in n" :key="index" class="vertical-input">
                <div class="parameter-container">
                  <span>{{ index }}</span>

                  <select
                    v-model="selectedParameters[index]"
                    class="consistent-size"
                    @change="onSelectChange(index)"
                  >
                    <option
                      v-for="option in customerKeys"
                      :key="option.keyName"
                      :value="option.keyName"
                    >
                      {{ option.DisplayName }}
                    </option>
                  </select>
                </div>
              </div>
            </div>

            <div v-if="headerFormat !== 'TEXT'">
              <p class="attachment-label">
                {{ $t('WHATSAPP_TEMPLATES.PARSER.ATTACHMENT_LABEL') }}
              </p>
              <input
                id="file"
                ref="file"
                type="file"
                :accept="acceptableFiles"
                required
                @change="uploadAttachment"
              />
            </div>
            <!-- Your other form elements go here -->
          </div>
        </div>
      </div>

      <!-- Right Column (Preview Campaign Component) -->
      <div class="form-section right-column">
        <preview-campaign
          :header-format="headerFormat"
          :body-content="bodyContent"
          :header-content="headerContent"
          :footer-content="footerContent"
          :cta-button="ctaButton"
          :quick-reply-button="quickReplyButton"
        />
      </div>

      <div class="modal-footer">
        <woot-button variant="clear" @click.prevent="onPrev">
          {{ $t('CAMPAIGN.ADD_BROADCAST.PREV_BUTTON_TEXT') }}
        </woot-button>
        <woot-button :class="sendButtonClass" :is-loading="uiFlags.isCreating">
          {{ $t('CAMPAIGN.ADD_BROADCAST.SEND_BUTTON_TEXT') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
const acceptableFileTypeDict = {
  IMAGE: 'image/png, image/gif, image/jpeg',
  VIDEO: 'video/mp4,video/x-m4v,video/*',
  DOCUMENT:
    'application/msword, application/vnd.ms-excel, application/vnd.ms-powerpoint, text/plain, application/pdf',
};
import { mapGetters } from 'vuex';
import { required } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import campaignMixin from 'shared/mixins/campaignMixin';
import { URLPattern } from 'urlpattern-polyfill';
import { CAMPAIGNS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import PreviewCampaign from './PreviewCampaign';

export default {
  components: {
    PreviewCampaign,
  },

  mixins: [alertMixin, campaignMixin],
  props: {
    audienceType: String,
    audience: Array,
    campaignName: String,
    scheduledTime: Date,
    selectedInboxId: Number,
    // Add other props as needed
  },
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
      selectedTemplateName: '', // New data property
      templateOptions: [],
      n: 0, // Set the desired number of woot-input elements
      inputValues: Array(2).fill(''),
      footerContent: '',
      headerContent: '',
      bodyContent: '',
      headerFormat: null,
      quickReplyButton: [],
      ctaButton: [],
      addBroadcastData: null,
      parameterOptions: [],
      selectedParameters: Array(this.n).fill(null),
      acceptableFiles: null,
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
    if (this.isOngoingType) {
      return {
        ...commonValidations,
        selectedSender: {
          required,
        },
        endPoint: {
          required,
          shouldBeAValidURLPattern(value) {
            try {
              // eslint-disable-next-line
              new URLPattern(value);
              return true;
            } catch (error) {
              return false;
            }
          },
          shouldStartWithHTTP(value) {
            if (value) {
              return (
                value.startsWith('https://') || value.startsWith('http://')
              );
            }
            return false;
          },
        },
        timeOnPage: {
          required,
        },
      };
    }
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
      inboxes: 'inboxes/getInboxes',
      customerKeys: 'contacts/getCustomerKeys',
    }),
    parameterArray() {
      return this.selectedParameters.map(selectedParameter => {
        const keyName = `$${selectedParameter}$$fallback`; // Modify this based on your requirements
        return keyName;
      });
    },
    hasParameters() {
      // Check if bodyContent contains placeholders like {{1}}, {{2}}, etc.
      const regex = /\{\{\d+\}\}/;
      return regex.test(this.bodyContent);
    },

    sendersAndBotList() {
      return [
        {
          id: 0,
          name: 'Bot',
        },
        ...this.senderList,
      ];
    },
    sendButtonClass() {
      return this.selectedTemplateName ? '' : 'blur-background';
    },
  },
  mounted() {
    this.$track(CAMPAIGNS_EVENTS.OPEN_NEW_CAMPAIGN_MODAL, {
      type: this.campaignType,
    });
    this.callApiWithCurl();
    this.fetchOptionsFromApi();
  },
  methods: {
    async onTemplateNameChange() {
      const selectedTemplate = this.templateOptions.find(
        template => template.name === this.selectedTemplateName
      );
      const regex = /\{{(\d+)}}/g;

      this.bodyContent =
        selectedTemplate.components.find(component => component.type === 'BODY')
          ?.text || '';
      this.footerContent =
        selectedTemplate.components.find(
          component => component.type === 'FOOTER'
        )?.text || '';
      this.headerContent =
        selectedTemplate.components.find(
          component => component.type === 'HEADER'
        )?.text || '';
      this.headerFormat =
        selectedTemplate.components.find(
          component => component.type === 'HEADER'
        )?.format || '';

      this.acceptableFiles = acceptableFileTypeDict[this.headerFormat];

      const quickReplyButtons =
        selectedTemplate.components.find(
          component => component.type === 'BUTTONS' && component.buttons
        ) || null;

      // Assign the quick reply buttons to the quickReplyButton property
      this.quickReplyButton = quickReplyButtons
        ? quickReplyButtons.buttons.map(button => ({ text: button.text }))
        : null;

      let maxNumber = 0;

      // Iterate over matches in the text
      const match = regex.exec(this.bodyContent);
      if (Array.isArray(match) && match.length) {
        const numberInBraces = parseInt(match[1], 10);
        maxNumber = Math.max(numberInBraces, maxNumber);
      }
      this.n = maxNumber;
      if (this.n) {
        try {
          const result = await this.fetchOptionsFromApi();
          this.parameterOptions = result;
        } catch (error) {
          this.parameterOptions = [];
        }
      }
    },

    async fetchOptionsFromApi() {
      try {
        await this.$store.dispatch('contacts/fetchCustomerKeys');
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
    onSelectChange() {},
    onClose() {
      this.$emit('on-close');
    },
    async uploadAttachment(event) {
      const file = event.target.files[0];
      const formData = new FormData();
      formData.append('attachment', file, file.name);
      const url = await this.$store.dispatch(
        'contacts/uploadAttachment',
        formData
      );
      this.attachmentData = { attachmentUrl: url };
    },
    onChange(value) {
      this.scheduledAt = value;
    },
    onPrev() {
      // Emit an event with necessary data
      this.$emit('prevButtonClick', {
        selectedTemplateName: this.selectedTemplateName,
        inputValues: this.inputValues,
        // Add other relevant data as needed
      });
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
    async callApiWithCurl() {
      const inboxWithWhatsappChannel = this.inboxes.find(
        inbox => inbox.id === this.selectedInboxId
      );

      this.templateOptions = inboxWithWhatsappChannel.message_templates;
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
    async addCampaign() {
      let audienceInfo = null;
      if (this.audienceType === 'contacts') {
        // For 'contacts' audience type, use contact IDs
        audienceInfo = this.audience.map(contact => contact.id);
      } else if (this.audienceType === 'labels') {
        // For 'labels' audience type, use label titles
        audienceInfo = this.audience.map(label => label.title);
      }
      const selectedTemplate = this.templateOptions.find(
        template => template.name === this.selectedTemplateName
      );

      try {
        const campaignDetails = {
          title: this.campaignName,
          message: 'Hello',
          template: {
            template: selectedTemplate,
            ...(this.parameterArray.length && {
              parameters: this.parameterArray.slice(1),
            }),
            ...(this.attachmentData && {
              attachment_url: this.attachmentData.attachmentUrl,
            }),
          },
          audience_type: this.audienceType,
          audience: audienceInfo,
          sender_id: null,
          inbox_id: this.selectedInboxId,
        };

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

.parameter-container {
  display: flex;
  justify-content: center;
  gap: 5px;
  align-items: center;
}

.vertical-input {
  display: flex;
  flex-direction: column;

  margin-bottom: 10px; /* Adjust the margin as needed */
}

.input-label {
  display: flex;
  align-items: center;
  margin-bottom: 5px; /* Adjust the margin as needed */
}
.blur-background {
  background-color: lightblue; // Set your desired blur color
}

.row {
  display: flex;
  justify-content: space-between;
}

.left-column {
  flex: 0 0 calc(50% - 10px); /* Adjust the width as needed, considering the margin between columns */
}

.right-column {
  flex: 0 0 calc(50% - 10px); /* Adjust the width as needed, considering the margin between columns */
}

.form-container {
  width: 100%; /* Ensure the form container takes full width */
  display: flex;
  flex-direction: column;
}
</style>
