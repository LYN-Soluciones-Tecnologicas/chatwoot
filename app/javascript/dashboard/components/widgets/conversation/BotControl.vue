<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import ConversationApi from 'dashboard/api/conversations';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: { NextButton },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      inboxes: 'inboxes/getInboxes',
    }),
    inboxHasBot() {
      const inboxId = this.currentChat?.inbox_id;
      if (!inboxId) return false;
      const inbox = this.inboxes.find(i => i.id === inboxId);
      return !!inbox?.agent_bot;
    },
    isBotPaused() {
      return this.currentChat?.custom_attributes?.bot_paused === true;
    },
  },
  methods: {
    async pauseBot() {
      await this.toggleBot(true);
    },
    async resumeBot() {
      await this.toggleBot(false);
    },
    async toggleBot(paused) {
      try {
        this.isLoading = true;
        if (paused) {
          await ConversationApi.pauseBot(this.conversationId);
        } else {
          await ConversationApi.resumeBot(this.conversationId);
        }
        const current = this.currentChat?.custom_attributes || {};
        this.$store.commit('UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES', {
          conversationId: this.conversationId,
          customAttributes: { ...current, bot_paused: paused },
        });
        const successKey = paused
          ? 'CONVERSATION.BOT_CONTROL.PAUSED_SUCCESS'
          : 'CONVERSATION.BOT_CONTROL.RESUMED_SUCCESS';
        useAlert(this.$t(successKey));
      } catch (error) {
        useAlert(this.$t('CONVERSATION.BOT_CONTROL.ERROR'));
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <div v-if="inboxHasBot" class="flex flex-col gap-2 py-2">
    <span class="text-xs font-medium text-n-slate-11 px-2">
      {{ $t('CONVERSATION.BOT_CONTROL.TITLE') }}
    </span>
    <div class="px-2">
      <NextButton
        v-if="!isBotPaused"
        sm
        slate
        faded
        icon="i-lucide-pause"
        :label="$t('CONVERSATION.BOT_CONTROL.PAUSE')"
        :is-loading="isLoading"
        @click="pauseBot"
      />
      <NextButton
        v-else
        sm
        blue
        icon="i-lucide-play"
        :label="$t('CONVERSATION.BOT_CONTROL.RESUME')"
        :is-loading="isLoading"
        @click="resumeBot"
      />
    </div>
  </div>
</template>
