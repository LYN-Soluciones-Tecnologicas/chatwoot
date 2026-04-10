<script>
import { useBranding } from 'shared/composables/useBranding';

const BRAND_NAME = 'LYN Soluciones Tec.';
const BRAND_URL = 'https://lynsoluciones.es/chatbot/';
const LOGO_THUMBNAIL =
  (window.globalConfig && window.globalConfig.LOGO_THUMBNAIL) ||
  '/brand-assets/logo_thumbnail.png';

export default {
  props: {
    disableBranding: {
      type: Boolean,
      default: false,
    },
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return {
      replaceInstallationName,
    };
  },
  data() {
    return {
      globalConfig: {
        brandName: BRAND_NAME,
        logoThumbnail: LOGO_THUMBNAIL,
        widgetBrandURL: BRAND_URL,
      },
    };
  },
  computed: {
    brandRedirectURL() {
      return BRAND_URL;
    },
  },
};
</script>

<template>
  <div
    v-if="globalConfig.brandName && !disableBranding"
    class="px-0 py-3 flex justify-center"
  >
    <a
      :href="brandRedirectURL"
      rel="noreferrer noopener nofollow"
      target="_blank"
      class="branding--link text-n-slate-11 hover:text-n-slate-12 cursor-pointer text-xs inline-flex grayscale-[1] hover:grayscale-0 hover:opacity-100 opacity-90 no-underline justify-center items-center leading-3"
    >
      <img
        class="ltr:mr-1 rtl:ml-1 max-w-3 max-h-3"
        :alt="globalConfig.brandName"
        :src="globalConfig.logoThumbnail"
      />
      <span>
        {{ replaceInstallationName($t('POWERED_BY')) }}
      </span>
    </a>
  </div>
  <div v-else class="p-3" />
</template>
