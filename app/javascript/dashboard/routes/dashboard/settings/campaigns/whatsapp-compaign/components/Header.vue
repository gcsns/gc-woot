<template>
  <header class="header-container">
    <div class="left-aligned">
      <back-button slot="Refresh" :back-url="backUrl" />
    </div>
  </header>
</template>

<script>
import BackButton from '../../../../../../components/widgets/BackButton.vue';
export default {
  components: {
    BackButton,
  },
  data() {
    return {
      backUrl: '/app/accounts/2/campaigns/broadcast',
    };
  },
};
</script>

<style lang="scss" scoped>
.header-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 95%;
  margin: auto;
  height: 5vh;
  .left-aligned {
    display: flex;
    align-items: center;
    .header-title {
      display: flex;
      align-items: center;
      justify-content: space-between;
      .title {
        font-size: 20px;
        margin-left: 10px;
      }
    }
  }
  .right-aligned {
    .refresh-btn {
      font-size: 16px;
      border: 1px solid blue;
      color: blue;
    }
  }
}
</style>
