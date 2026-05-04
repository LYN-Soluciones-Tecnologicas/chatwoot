<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getContrastingTextColor } from '@chatwoot/utils';
import MessageCopyButton from './MessageCopyButton.vue';

export default {
  name: 'UserMessageBubble',
  components: { MessageCopyButton },
  props: {
    message: {
      type: String,
      default: '',
    },
    widgetColor: {
      type: String,
      default: '',
    },
  },
  setup() {
    const { formatMessage } = useMessageFormatter();
    return {
      formatMessage,
    };
  },
  computed: {
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
};
</script>

<template>
  <div class="flex flex-col items-end gap-1">
    <div
      v-dompurify-html="formatMessage(message, false)"
      class="chat-bubble user"
      :style="{ background: widgetColor, color: textColor }"
    />
    <MessageCopyButton
      :text="message"
      :label="$t('COMPONENTS.MESSAGE_BUBBLE.COPY_MESSAGE')"
    />
  </div>
</template>

<style lang="scss" scoped>
.chat-bubble.user::v-deep {
  p code {
    @apply bg-n-alpha-2 dark:bg-n-alpha-1 text-white;
  }

  pre {
    @apply text-white bg-n-alpha-2 dark:bg-n-alpha-1;

    code {
      @apply bg-transparent text-white;
    }
  }

  blockquote {
    @apply bg-transparent border-n-slate-7 ltr:border-l-2 rtl:border-r-2 border-solid;

    p {
      @apply text-n-slate-5 dark:text-n-slate-12/90;
    }
  }
}
</style>
