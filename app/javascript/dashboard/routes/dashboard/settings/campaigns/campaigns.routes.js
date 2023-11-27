import Index from './Index';
import SettingsContent from '../Wrapper';
import { frontendURL } from '../../../../helper/URLHelper';
import WhatsappCampaign from './whatsapp-compaign/WhatsappCampaign';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: SettingsContent,
      props: {
        headerTitle: 'CAMPAIGN.ONGOING.HEADER',
        icon: 'arrow-swap',
      },
      children: [
        {
          path: '',
          redirect: 'ongoing',
        },
        {
          path: 'ongoing',
          name: 'settings_account_campaigns',
          roles: ['administrator'],
          component: { ...Index },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: SettingsContent,
      props: {
        headerTitle: 'CAMPAIGN.ONE_OFF.HEADER',
        icon: 'sound-source',
      },
      children: [
        {
          path: 'one_off',
          name: 'one_off',
          roles: ['administrator'],
          component: { ...Index },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: SettingsContent,
      props: {
        headerTitle: 'CAMPAIGN.BROADCAST.HEADER',
        icon: 'sound-source',
      },
      children: [
        {
          path: 'broadcast',
          name: 'broadcast_campaigns',
          roles: ['administrator'],
          component: { ...Index },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/campaigns/broadcast/:campaignId'),
      name: 'campaign_single',
      roles: ['administrator'],
      component: WhatsappCampaign,
    },
  ],
};
