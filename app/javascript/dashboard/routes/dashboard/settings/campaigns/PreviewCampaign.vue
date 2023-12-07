<template>
  <div class="outer-box">
    <div class="preview-heading">Template Preview</div>
    <div class="inner-box">
      <div v-if="headerFormat && headerFormat !== 'text'" class="centered-images-container">
        <img
          v-if="headerFormat !== 'TEXT'"
          :src="templateTypeImages[headerFormat]"
          alt=""
          width="236"
          height="136"
        />
      </div>
      <div class="header-container">
        <p>{{ headerContent }}</p>
      </div>
      <div class="body-container">
        <p>{{ bodyContent }}</p>
      </div>
      <div class="footer-container">
        <p>{{ footerContent }}</p>
      </div>
      
    </div>
    <div v-if="ctaButton">
  <woot-button v-for="ctaBtn in ctaButton" :key="ctaBtn.idx" class="interactive-btn" :title="ctaBtn.value">
    <fluent-icon icon="arrow-clockwise" /> {{ ctaBtn.label }}
  </woot-button>
</div>
    
<div v-if="quickReplyButton">
  <woot-button
    v-for="quickReplyBtn in quickReplyButton"
    :key="quickReplyBtn.idx"
    class="interactive-btn"
    :title="quickReplyBtn.text"
  >
    <div class="btn-content">
          <fluent-icon icon="arrow-up-right" class="fluent-icon" />
          {{ quickReplyBtn.text }}
        </div>
  </woot-button>
</div>

  </div>
</template>

<script>
export default {
  props: {
    headerFormat: String,
    bodyContent: String,
    headerContent: String,
    footerContent: String,
    ctaButton: Array,
    quickReplyButton: Array,
  },
  data() {
    return {
      templateTypeImages: {
        IMAGE: '@/assets/images/image.svg',
        VIDEO: '@/assets/images/video.svg',
        LOCATION: '@/assets/images/location.svg',
        FILE: '@/assets/images/file.svg',
      },
    };
  },
  created() {
  },
  mounted() {

  },
};
</script>

<style scoped>
.outer-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: #F9FAFC 0% 0% no-repeat;
  min-height: 400px;
  overflow: scroll;
  min-width: 100%;
}

.preview-heading {
  width: 127px;
  height: 18px;
  margin-top: 15px;
  margin-bottom: 6px;
  text-align: left;
  font: normal normal 600 16px/19px Proxima Nova;
  letter-spacing: 0px;
  color: #2C2E30;
  opacity: 1;
}

.inner-box {
  width: 90%;
  min-height: 60px;
  background: white;
  border: 1px solid #d7d7d7;
  border-radius: 4px;
  opacity: 1;
  padding: 10px;
}

.body-container {
  overflow-wrap: break-word;
  width: 100%;
  min-height: 90px;
  padding: 5px;
  background: white;
  border-radius: 4px;
  opacity: 1;
  letter-spacing: 0px;
  font: normal normal medium 14px/18px Proxima Nova;
  color: #777777;
}

.header-container {
  font: normal normal 600 14px/16px Proxima Nova;
  text-align: left;
  color: #2C2E30;
}

.footer-container {
  text-align: left;
  font: normal normal medium 14px/16px Proxima Nova;
  letter-spacing: 0px;
  color: #777777;
  opacity: 1;
}

.boxInsideInner p {
  font-size: 12px;
  color: #777777;
}

.btn-content {
  display: flex;
  align-items: center;
}

.centered-images-container {
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
  padding-bottom: 8px;
}
.interactive-btn {
  width: 100%; /* or width: 100% */
  background: #F9FAFC 0% 0% no-repeat padding-box;
  border: 1px solid #D7D7D7;
  color: #1e90ff;
  align-items: center;
  justify-content: center;
  display: flex; /* Add display: flex; */
  flex-direction: column;
  text-align: center;
  margin-top: 10px;
  padding: 10px; /* Add the unit (e.g., px) for padding */
}
</style>
