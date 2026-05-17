<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import { popoutChatWindow } from '../helpers/popoutHelper';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import ExportConversationMenu from 'widget/components/ExportConversationMenu.vue';
import { CONVERSATION_STATUS } from 'shared/constants/messages';

const props = defineProps({
  showPopoutButton: {
    type: Boolean,
    default: false,
  },
  showEndConversationButton: {
    type: Boolean,
    default: true,
  },
});

const store = useStore();
const { locale, t } = useI18n();

const channelConfig = computed(() => window.chatwootWebChannel);
const conversationAttributes = computed(
  () => store.getters['conversationAttributes/getConversationParams']
);
const canUserEndConversation = computed(
  () => store.getters['appConfig/getCanUserEndConversation']
);
const hideMessageBubble = computed(
  () => store.getters['appConfig/getHideMessageBubble']
);
const isMobile = computed(() => store.getters['appConfig/getIsMobile']);
const isWidgetFullscreen = computed(
  () => store.getters['appConfig/getIsWidgetFullscreen']
);

const conversationStatus = computed(() => conversationAttributes.value.status);
const canLeaveConversation = computed(() =>
  [
    CONVERSATION_STATUS.OPEN,
    CONVERSATION_STATUS.SNOOZED,
    CONVERSATION_STATUS.PENDING,
  ].includes(conversationStatus.value)
);
const isIframe = computed(() => IFrameHelper.isIFrame());
const isRNWebView = computed(() => !!RNHelper.isRNWebView());
const hasEndConversationEnabled = computed(() =>
  channelConfig.value.enabledFeatures.includes('end_conversation')
);
const hasWidgetOptions = computed(
  () =>
    props.showPopoutButton ||
    conversationStatus.value === CONVERSATION_STATUS.OPEN
);
const showHeaderActions = computed(
  () => isIframe.value || isRNWebView.value || hasWidgetOptions.value
);
const showCloseButton = computed(
  () =>
    isMobile.value ||
    isRNWebView.value ||
    hideMessageBubble.value ||
    isWidgetFullscreen.value
);
const showPopoutAction = computed(
  () => props.showPopoutButton && !isMobile.value && !isWidgetFullscreen.value
);
const showFullscreenButton = computed(
  () => isIframe.value && !isRNWebView.value && !isMobile.value
);
const fullscreenButtonTitle = computed(() =>
  isWidgetFullscreen.value ? t('COLLAPSE_CHAT') : t('EXPAND_CHAT')
);

const closeWindow = () => {
  if (IFrameHelper.isIFrame()) {
    IFrameHelper.sendMessage({ event: 'closeWindow' });
  } else if (RNHelper.isRNWebView()) {
    RNHelper.sendMessage({ type: 'close-widget' });
  }
};

const popoutWindow = () => {
  closeWindow();
  const {
    location: { origin },
    chatwootWebChannel: { websiteToken },
    authToken,
  } = window;

  popoutChatWindow(origin, websiteToken, locale.value, authToken);
};

const endConversation = async () => {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('END_CONVERSATION_CONFIRMATION'))) {
    return;
  }

  try {
    await store.dispatch('conversation/endConversation');
  } catch (error) {
    // Backend deletion failed: keep the session intact so the visitor
    // doesn't lose access to a conversation that still exists.
    return;
  }

  // Conversation deleted on the backend. Now clear the local session so the
  // visitor starts fresh. Cookies (cw_conversation / cw_user) live on the
  // parent domain, so the iframe must ask the SDK to run its reset().
  if (IFrameHelper.isIFrame()) {
    IFrameHelper.sendMessage({ event: 'resetWidget' });
  } else if (RNHelper.isRNWebView()) {
    RNHelper.sendMessage({ type: 'close-widget' });
  } else {
    // Popout / standalone window: no parent SDK, reload to reset state.
    window.location.reload();
  }
};

const toggleFullscreen = () => {
  IFrameHelper.sendMessage({
    event: 'toggleFullscreen',
    isFullscreen: !isWidgetFullscreen.value,
  });
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div v-if="showHeaderActions" class="actions flex items-center gap-3">
    <ExportConversationMenu />
    <button
      v-if="
        canLeaveConversation &&
        canUserEndConversation &&
        hasEndConversationEnabled &&
        showEndConversationButton
      "
      class="button transparent compact"
      :title="t('END_CONVERSATION')"
      @click="endConversation"
    >
      <FluentIcon icon="sign-out" size="22" class="text-n-slate-12" />
    </button>
    <button
      v-if="showPopoutAction"
      class="button transparent compact new-window--button"
      :title="t('OPEN_CHAT')"
      @click="popoutWindow"
    >
      <FluentIcon icon="open" size="22" class="text-n-slate-12" />
    </button>
    <button
      v-if="showFullscreenButton"
      class="button transparent compact fullscreen-button"
      :title="fullscreenButtonTitle"
      :aria-label="fullscreenButtonTitle"
      @click="toggleFullscreen"
    >
      <FluentIcon
        :icon="isWidgetFullscreen ? 'collapse' : 'expand'"
        size="22"
        class="text-n-slate-12"
      />
    </button>
    <button
      v-if="showCloseButton"
      class="button transparent compact close-button"
      :title="t('CLOSE_CHAT')"
      :aria-label="t('CLOSE_CHAT')"
      @click="closeWindow"
    >
      <FluentIcon icon="dismiss" size="24" class="text-n-slate-12" />
    </button>
  </div>
</template>
