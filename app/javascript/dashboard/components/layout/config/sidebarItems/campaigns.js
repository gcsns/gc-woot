import { frontendURL } from '../../../../helper/URLHelper';

const campaigns = accountId => ({
  parentNav: 'campaigns',
  routes: ['settings_account_campaigns', 'one_off', 'broadcast_campaigns'],
  menuItems: [
    {
      icon: 'arrow-swap',
      label: 'ONGOING',
      key: 'ongoingCampaigns',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/ongoing`),
      toStateName: 'settings_account_campaigns',
    },
    {
      key: 'oneOffCampaigns',
      icon: 'sound-source',
      label: 'ONE_OFF',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/one_off`),
      toStateName: 'one_off',
    },
    {
      key: 'broadcastCampaigns',
      label: 'BROADCAST',
      icon: 'arrow-swap',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/campaigns/broadcast`),
      toStateName: 'broadcast_campaigns',
    },
  ],
});

export default campaigns;
