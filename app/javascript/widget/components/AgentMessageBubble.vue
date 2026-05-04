<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { exportConversation } from 'widget/api/conversation';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import ChatCard from 'shared/components/ChatCard.vue';
import ChatForm from 'shared/components/ChatForm.vue';
import ChatOptions from 'shared/components/ChatOptions.vue';
import ChatArticle from './template/Article.vue';
import EmailInput from './template/EmailInput.vue';
import CustomerSatisfaction from 'shared/components/CustomerSatisfaction.vue';
import IntegrationCard from './template/IntegrationCard.vue';
import MessageCopyButton from './MessageCopyButton.vue';

export default {
  name: 'AgentMessageBubble',
  components: {
    FluentIcon,
    ChatArticle,
    ChatCard,
    ChatForm,
    ChatOptions,
    EmailInput,
    CustomerSatisfaction,
    IntegrationCard,
    MessageCopyButton,
  },
  props: {
    message: { type: String, default: null },
    contentType: { type: String, default: null },
    messageType: { type: Number, default: null },
    messageId: { type: Number, default: null },
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
  },
  setup() {
    const { formatMessage, getPlainText, truncateMessage, highlightContent } =
      useMessageFormatter();
    return {
      formatMessage,
      getPlainText,
      truncateMessage,
      highlightContent,
    };
  },
  data() {
    return {
      isStructuredExportMenuOpen: false,
      isStructuredExporting: false,
    };
  },
  computed: {
    isTemplate() {
      return this.messageType === 3;
    },
    isTemplateEmail() {
      return this.contentType === 'input_email';
    },
    isCards() {
      return this.contentType === 'cards';
    },
    isOptions() {
      return this.contentType === 'input_select';
    },
    isForm() {
      return this.contentType === 'form';
    },
    isArticle() {
      return this.contentType === 'article';
    },
    isCSAT() {
      return this.contentType === 'input_csat';
    },
    isIntegrations() {
      return this.contentType === 'integrations';
    },
    isTextMessage() {
      return (
        !this.isCards &&
        !this.isOptions &&
        !this.isForm &&
        !this.isArticle &&
        !this.isCSAT
      );
    },
    hasStructuredContent() {
      const content = this.message?.trim();
      if (!content) return false;

      return this.hasMarkdownTable(content) || this.hasJsonBlock(content);
    },
  },
  beforeUnmount() {
    document.removeEventListener(
      'click',
      this.handleStructuredExportOutsideClick
    );
  },
  methods: {
    onResponse(messageResponse) {
      this.$store.dispatch('message/update', messageResponse);
    },
    onOptionSelect(selectedOption) {
      this.onResponse({
        submittedValues: [selectedOption],
        messageId: this.messageId,
      });
    },
    onFormSubmit(formValues) {
      const formValuesAsArray = Object.keys(formValues).map(key => ({
        name: key,
        value: formValues[key],
      }));
      this.onResponse({
        submittedValues: formValuesAsArray,
        messageId: this.messageId,
      });
    },
    toggleStructuredExportMenu() {
      if (this.isStructuredExporting) return;

      this.setStructuredExportMenuOpen(!this.isStructuredExportMenuOpen);
    },
    setStructuredExportMenuOpen(isOpen) {
      this.isStructuredExportMenuOpen = isOpen;
      if (isOpen) {
        document.addEventListener(
          'click',
          this.handleStructuredExportOutsideClick
        );
      } else {
        document.removeEventListener(
          'click',
          this.handleStructuredExportOutsideClick
        );
      }
    },
    handleStructuredExportOutsideClick(event) {
      const menu = this.$refs.structuredExportMenu;
      if (menu && !menu.contains(event.target)) {
        this.setStructuredExportMenuOpen(false);
      }
    },
    async handleStructuredExport(format) {
      if (this.isStructuredExporting) return;

      this.isStructuredExporting = true;
      this.setStructuredExportMenuOpen(false);
      try {
        await exportConversation(format, this.messageId);
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('EXPORT_CONVERSATION.SUCCESS'),
          type: 'success',
        });
      } catch {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('EXPORT_CONVERSATION.ERROR'),
        });
      } finally {
        this.isStructuredExporting = false;
      }
    },
    hasMarkdownTable(content) {
      const lines = content.split(/\r?\n/).map(line => line.trim());

      return lines.some((line, index) => {
        const nextLine = lines[index + 1];
        return (
          line.includes('|') && nextLine && this.isMarkdownSeparator(nextLine)
        );
      });
    },
    isMarkdownSeparator(line) {
      const cells = line
        .replace(/^\|/, '')
        .replace(/\|$/, '')
        .split('|')
        .map(cell => cell.trim());

      return cells.length > 1 && cells.every(cell => /^:?-{3,}:?$/.test(cell));
    },
    hasJsonBlock(content) {
      const fencedJson = content.match(/```(?:json)?\s*\n([\s\S]*?)\n```/i);
      if (fencedJson && this.isStructuredJson(fencedJson[1])) return true;

      return /^\s*[[{]/.test(content) && this.isStructuredJson(content);
    },
    isStructuredJson(payload) {
      try {
        const value = JSON.parse(payload);
        if (Array.isArray(value)) return value.length > 0;

        return (
          value && typeof value === 'object' && Object.keys(value).length > 0
        );
      } catch {
        return false;
      }
    },
  },
};
</script>

<template>
  <div class="chat-bubble-wrap">
    <div
      v-if="isTextMessage"
      class="chat-bubble agent bg-n-background dark:bg-n-solid-3 text-n-slate-12"
    >
      <div
        v-dompurify-html="formatMessage(message, false)"
        class="message-content text-n-slate-12"
      />
      <div
        v-if="hasStructuredContent"
        ref="structuredExportMenu"
        class="relative mt-2 flex justify-end"
      >
        <button
          type="button"
          class="inline-flex items-center gap-1 rounded-md border border-n-weak px-2 py-1 text-xs text-n-slate-11 hover:bg-n-slate-2 disabled:cursor-not-allowed disabled:opacity-60 dark:hover:bg-n-solid-3"
          :disabled="isStructuredExporting"
          :title="$t('EXPORT_CONVERSATION.DOWNLOAD_STRUCTURED_DATA')"
          @click.stop="toggleStructuredExportMenu"
        >
          <FluentIcon icon="arrow-download" size="14" />
          <span>{{ $t('EXPORT_CONVERSATION.DOWNLOAD_STRUCTURED_DATA') }}</span>
        </button>
        <div
          v-if="isStructuredExportMenuOpen"
          class="absolute right-0 top-8 z-50 min-w-[120px] rounded-md border border-n-weak bg-white py-1 shadow-lg dark:bg-n-solid-2"
        >
          <button
            type="button"
            class="w-full px-3 py-2 text-left text-sm text-n-slate-12 hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
            @click.stop="handleStructuredExport('csv')"
          >
            {{ $t('EXPORT_CONVERSATION.FORMAT_CSV_SHORT') }}
          </button>
          <button
            type="button"
            class="w-full px-3 py-2 text-left text-sm text-n-slate-12 hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
            @click.stop="handleStructuredExport('xlsx')"
          >
            {{ $t('EXPORT_CONVERSATION.FORMAT_XLSX_SHORT') }}
          </button>
        </div>
      </div>
      <EmailInput
        v-if="isTemplateEmail"
        :message-id="messageId"
        :message-content-attributes="messageContentAttributes"
      />

      <IntegrationCard
        v-if="isIntegrations"
        :message-id="messageId"
        :meeting-data="messageContentAttributes.data"
      />
    </div>
    <MessageCopyButton
      v-if="isTextMessage"
      class="mt-1"
      :text="message"
      :label="$t('COMPONENTS.MESSAGE_BUBBLE.COPY_RESPONSE')"
    />
    <div v-if="isOptions">
      <ChatOptions
        :title="message"
        :options="messageContentAttributes.items"
        :hide-fields="!!messageContentAttributes.submitted_values"
        @option-select="onOptionSelect"
      />
    </div>
    <ChatForm
      v-if="isForm && !messageContentAttributes.submitted_values"
      :items="messageContentAttributes.items"
      :button-label="messageContentAttributes.button_label"
      :submitted-values="messageContentAttributes.submitted_values"
      @submit="onFormSubmit"
    />
    <div v-if="isCards">
      <ChatCard
        v-for="item in messageContentAttributes.items"
        :key="item.title"
        :media-url="item.media_url"
        :title="item.title"
        :description="item.description"
        :actions="item.actions"
      />
    </div>
    <div v-if="isArticle">
      <ChatArticle :items="messageContentAttributes.items" />
    </div>
    <CustomerSatisfaction
      v-if="isCSAT"
      :message-content-attributes="messageContentAttributes.submitted_values"
      :display-type="messageContentAttributes.display_type"
      :message="message"
      :message-id="messageId"
    />
  </div>
</template>
