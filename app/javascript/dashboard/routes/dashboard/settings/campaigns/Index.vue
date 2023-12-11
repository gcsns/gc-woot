<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openAddPopup"
    >
      {{ buttonText }}
    </woot-button>
    <campaign />
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
     <add-broadcast-campaign v-if="isBroadcastType" @on-close="hideAddPopup"/>
      <add-campaign v-else @on-close="hideAddPopup" />

    </woot-modal>
  </div>
</template>

<script>
import campaignMixin from 'shared/mixins/campaignMixin';
import Campaign from './Campaign.vue';
import AddCampaign from './AddCampaign';
import AddBroadcastCampaign from './AddBroadcastCampaign.vue';

export default {
  components: {
    Campaign,
    AddCampaign,
    AddBroadcastCampaign,
  },
  mixins: [campaignMixin],
  data() {
    return { showAddPopup: false };
  },
  computed: {
    buttonText() {
      if (this.isOngoingType) {
        return this.$t('CAMPAIGN.HEADER_BTN_TXT.ONGOING');
      }
      if (this.isBroadcastType) {
        return this.$t('CAMPAIGN.HEADER_BTN_TXT.BROADCAST');
      }
      return this.$t('CAMPAIGN.HEADER_BTN_TXT.ONE_OFF');
    },
  },
  mounted() {
    this.$store.dispatch('campaigns/get');
  },
  methods: {
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
  },
};
</script>
