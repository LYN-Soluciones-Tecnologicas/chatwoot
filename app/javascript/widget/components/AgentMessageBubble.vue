<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import ChatCard from 'shared/components/ChatCard.vue';
import ChatForm from 'shared/components/ChatForm.vue';
import ChatOptions from 'shared/components/ChatOptions.vue';
import ChatArticle from './template/Article.vue';
import EmailInput from './template/EmailInput.vue';
import CustomerSatisfaction from 'shared/components/CustomerSatisfaction.vue';
import IntegrationCard from './template/IntegrationCard.vue';

export default {
  name: 'AgentMessageBubble',
  components: {
    ChatArticle,
    ChatCard,
    ChatForm,
    ChatOptions,
    EmailInput,
    CustomerSatisfaction,
    IntegrationCard,
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
  },
  mounted() {
    this.enhanceTables();
  },
  updated() {
    this.enhanceTables();
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
    enhanceTables() {
      const root = this.$refs.messageContent;
      if (!root) return;
      const tables = root.querySelectorAll('table:not([data-cw-enhanced])');
      tables.forEach((table, idx) => {
        table.setAttribute('data-cw-enhanced', '1');
        const actions = document.createElement('div');
        actions.className = 'cw-table-actions';
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'cw-table-download-btn';
        button.textContent = this.$t('EXPORT_CONVERSATION.DOWNLOAD_TABLE');
        button.addEventListener('click', () =>
          this.downloadTableAsHtml(table, idx + 1)
        );
        actions.appendChild(button);
        table.parentNode.insertBefore(actions, table.nextSibling);
      });
    },
    downloadTableAsHtml(tableElement, tableNumber) {
      const title = `${this.$t('EXPORT_CONVERSATION.TABLE_TITLE')} ${tableNumber}`;
      const html = `<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>${title}</title>
<style>
body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;padding:24px;color:#111}
h1{font-size:18px;margin:0 0 16px}
table{border-collapse:collapse;width:100%}
th,td{border:1px solid #d1d5db;padding:8px 12px;text-align:left;vertical-align:top}
th{background:#f3f4f6;font-weight:600}
tr:nth-child(even) td{background:#fafafa}
</style></head><body>
<h1>${title}</h1>
${tableElement.outerHTML}
</body></html>`;
      const blob = new Blob([html], { type: 'text/html;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `tabla-${tableNumber}.html`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    },
  },
};
</script>

<template>
  <div class="chat-bubble-wrap">
    <div
      v-if="
        !isCards && !isOptions && !isForm && !isArticle && !isCards && !isCSAT
      "
      class="chat-bubble agent bg-n-background dark:bg-n-solid-3 text-n-slate-12"
    >
      <div
        ref="messageContent"
        v-dompurify-html="formatMessage(message, false)"
        class="message-content text-n-slate-12"
      />
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

<style>
.cw-table-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 6px;
  margin-bottom: 4px;
}
.cw-table-download-btn {
  font-size: 12px;
  line-height: 1;
  padding: 6px 10px;
  border-radius: 6px;
  border: 1px solid rgba(0, 0, 0, 0.12);
  background: rgba(0, 0, 0, 0.04);
  color: inherit;
  cursor: pointer;
  transition: background 120ms ease;
}
.cw-table-download-btn:hover {
  background: rgba(0, 0, 0, 0.08);
}
.dark .cw-table-download-btn {
  border-color: rgba(255, 255, 255, 0.16);
  background: rgba(255, 255, 255, 0.06);
}
.dark .cw-table-download-btn:hover {
  background: rgba(255, 255, 255, 0.12);
}
</style>
