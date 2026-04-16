<script>
import { mapGetters } from 'vuex';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import { popoutChatWindow } from '../helpers/popoutHelper';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import ExportConversationMenu from 'widget/components/ExportConversationMenu.vue';
import configMixin from 'widget/mixins/configMixin';
import { CONVERSATION_STATUS } from 'shared/constants/messages';

export default {
  name: 'HeaderActions',
  components: { FluentIcon, ExportConversationMenu },
  mixins: [configMixin],
  props: {
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
    showEndConversationButton: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    ...mapGetters({
      conversationAttributes: 'conversationAttributes/getConversationParams',
      canUserEndConversation: 'appConfig/getCanUserEndConversation',
      hideMessageBubble: 'appConfig/getHideMessageBubble',
      isMobile: 'appConfig/getIsMobile',
      isWidgetFullscreen: 'appConfig/getIsWidgetFullscreen',
    }),
    canLeaveConversation() {
      return [
        CONVERSATION_STATUS.OPEN,
        CONVERSATION_STATUS.SNOOZED,
        CONVERSATION_STATUS.PENDING,
      ].includes(this.conversationStatus);
    },
    isIframe() {
      return IFrameHelper.isIFrame();
    },
    isRNWebView() {
      return RNHelper.isRNWebView();
    },
    showHeaderActions() {
      return this.isIframe || this.isRNWebView || this.hasWidgetOptions;
    },
    conversationStatus() {
      return this.conversationAttributes.status;
    },
    hasWidgetOptions() {
      return this.showPopoutButton || this.conversationStatus === 'open';
    },
    showCloseButton() {
      return (
        this.isMobile ||
        this.isRNWebView ||
        this.hideMessageBubble ||
        this.isWidgetFullscreen
      );
    },
    showPopoutAction() {
      return (
        this.showPopoutButton && !this.isMobile && !this.isWidgetFullscreen
      );
    },
    showFullscreenButton() {
      return this.isIframe && !this.isRNWebView && !this.isMobile;
    },
    fullscreenButtonTitle() {
      return this.isWidgetFullscreen
        ? this.$t('COLLAPSE_CHAT')
        : this.$t('EXPAND_CHAT');
    },
  },
  methods: {
    popoutWindow() {
      this.closeWindow();
      const {
        location: { origin },
        chatwootWebChannel: { websiteToken },
        authToken,
      } = window;
      popoutChatWindow(
        origin,
        websiteToken,
        this.$root.$i18n.locale,
        authToken
      );
    },
    closeWindow() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'closeWindow' });
      } else if (RNHelper.isRNWebView) {
        RNHelper.sendMessage({ type: 'close-widget' });
      }
    },
    resolveConversation() {
      this.$store.dispatch('conversation/resolveConversation');
    },
    toggleFullscreen() {
      IFrameHelper.sendMessage({
        event: 'toggleFullscreen',
        isFullscreen: !this.isWidgetFullscreen,
      });
    },
  },
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
      :title="$t('END_CONVERSATION')"
      @click="resolveConversation"
    >
      <FluentIcon icon="sign-out" size="22" class="text-n-slate-12" />
    </button>
    <button
      v-if="showPopoutAction"
      class="button transparent compact new-window--button"
      :title="$t('OPEN_CHAT')"
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
      :title="$t('CLOSE_CHAT')"
      :aria-label="$t('CLOSE_CHAT')"
      @click="closeWindow"
    >
      <FluentIcon icon="dismiss" size="24" class="text-n-slate-12" />
    </button>
  </div>
</template>
