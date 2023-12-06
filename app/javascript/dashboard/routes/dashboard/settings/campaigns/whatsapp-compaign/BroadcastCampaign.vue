<template>
  <div class="campaign-container">
    <campaign-header />
    <campaign-analytics />
  </div>
</template>

<script>
import CampaignHeader from './components/Header.vue';
import CampaignAnalytics from './components/CampaignAnalytics.vue';
export default {
  components: {
    CampaignHeader,
    CampaignAnalytics,
  },
  props: {},
  data() {
    return {};
  },
  computed: {},
  methods: {},
};
</script>

<style>
.campaign-container {
  width: 100%;
}
</style>
