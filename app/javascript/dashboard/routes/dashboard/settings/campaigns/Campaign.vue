<template>
  <div class="column content-box">
    <div v-if="isBroadcastType" class="search-bar">
      <div class="search-container">
        <input
          v-model="searchQuery"
          placeholder="Search by campaign name"
          class="search-container"
        />
        <button class="search-button" @click="searchCampaigns">
          <fluent-icon icon="search" />
        </button>
      </div>
    </div>
    <campaigns-table
      :campaigns="displayedCampaigns"
      :show-empty-result="showEmptyResult"
      :is-loading="uiFlags.isFetching"
      :campaign-type="type"
      @on-edit-click="openEditPopup"
      @on-delete-click="openDeletePopup"
    />
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-campaign
        :selected-campaign="selectedCampaign"
        @on-close="hideEditPopup"
      />
    </woot-modal>
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CAMPAIGN.DELETE.CONFIRM.TITLE')"
      :message="$t('CAMPAIGN.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="$t('CAMPAIGN.DELETE.CONFIRM.YES')"
      :reject-text="$t('CAMPAIGN.DELETE.CONFIRM.NO')"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import campaignMixin from 'shared/mixins/campaignMixin';
import CampaignsTable from './CampaignsTable';
import EditCampaign from './EditCampaign';
export default {
  components: {
    CampaignsTable,
    EditCampaign,
  },
  mixins: [alertMixin, campaignMixin],
  props: {
    type: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      showEditPopup: false,
      selectedCampaign: {},
      showDeleteConfirmationPopup: false,
      searchQuery: '',
      filteredCampaigns: [],
      searchIcon: 'Search',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'campaigns/getUIFlags',
      labelList: 'labels/getLabels',
    }),
    campaigns() {
      return this.$store.getters['campaigns/getCampaigns'](this.campaignType);
    },
    displayedCampaigns() {
      if (this.searchQuery.length > 0) {
        // Filter campaigns based on partial match in title
        return this.filteredCampaigns;
      }
      // If no search query, return all campaigns
      return this.campaigns;
    },
    showEmptyResult() {
      const hasEmptyResults =
        !this.uiFlags.isFetching && this.campaigns.length === 0;
      return hasEmptyResults;
    },
  },
  methods: {
    searchCampaigns() {
      this.filteredCampaigns = this.campaigns.filter(campaign =>
        campaign.title.toLowerCase().includes(this.searchQuery.toLowerCase())
      );
    },

    openEditPopup(response) {
      const { row: campaign } = response;
      this.selectedCampaign = campaign;
      this.showEditPopup = true;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedCampaign = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.closeDeletePopup();
      const {
        row: { id },
      } = this.selectedCampaign;
      this.deleteCampaign(id);
    },
    async deleteCampaign(id) {
      try {
        await this.$store.dispatch('campaigns/delete', id);
        this.showAlert(this.$t('CAMPAIGN.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('CAMPAIGN.DELETE.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<style scoped lang="scss">
.button-wrapper {
  display: flex;
  justify-content: flex-end;
  padding-bottom: var(--space-one);
}

.search-bar input {
  flex: 1;
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;

  margin-bottom: 15px;
  padding-left: 40px; /* Adjust this value to leave space for the icon and text */
}

.search-container {
  position: relative;
}

.search-container input {
  padding-right: 30px; /* Adjust this value to leave space for the icon */
}

.search-container button {
  position: absolute;
  top: 0;
  height: 100%;
  display: flex;
  align-items: right;
  padding: 0 8px;
  cursor: pointer;
}

.search-button {
  align-itmes: right;
  color: grey;
  margin-top: 5px;
}

.content-box .page-top-bar::v-deep {
  padding: var(--space-large) var(--space-large) var(--space-zero);
}
</style>
