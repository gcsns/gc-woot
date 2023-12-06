<template>
  <iframe
    :src="url"
    title="Campaign Analytics"
    style="height: 100%; width: 100%"
  />
</template>

<script>
export default {
  components: {},
  props: {},
  data() {
    return {
      url: '',
    };
  },
  computed: {},
  mounted() {
    const currentUrl = window.location.pathname;
    const split = currentUrl.split('/');
    const id = split[split.length - 1];
    const token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE3MzI4MjQwMDAwMDB9.q2UqaJswlXkpqi4xk1Grp7vXj1g9DE9OvyjH4HV2DbU';
    const path = `http://localhost:3001/campaignDetails/${id}?hideSideBar=true?token=${token}`;
    this.url = path;
  },
  methods: {},
};
</script>
