<script setup>
import { computed, onBeforeUnmount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { emitter } from 'shared/helpers/mitt';

const props = defineProps({
  text: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const copied = ref(false);
let resetCopiedTimer;

const copyText = computed(() => String(props.text ?? ''));
const hasText = computed(() => copyText.value.trim().length > 0);
const buttonLabel = computed(() =>
  copied.value ? t('COMPONENTS.MESSAGE_BUBBLE.COPIED') : props.label
);

const resetCopied = () => {
  copied.value = false;
};

const handleCopy = async () => {
  if (!hasText.value) return;

  try {
    await copyTextToClipboard(copyText.value);
    copied.value = true;
    clearTimeout(resetCopiedTimer);
    resetCopiedTimer = window.setTimeout(resetCopied, 1800);
  } catch {
    emitter.emit(BUS_EVENTS.SHOW_ALERT, {
      message: t('COMPONENTS.MESSAGE_BUBBLE.COPY_ERROR'),
    });
  }
};

onBeforeUnmount(() => {
  clearTimeout(resetCopiedTimer);
});
</script>

<template>
  <div class="flex">
    <button
      v-if="hasText"
      type="button"
      class="inline-flex h-6 w-6 items-center justify-center rounded-md text-n-slate-11 transition-colors hover:bg-n-slate-2 hover:text-n-slate-12 dark:hover:bg-n-solid-3"
      :title="buttonLabel"
      :aria-label="buttonLabel"
      @click.stop="handleCopy"
    >
      <FluentIcon
        :icon="copied ? 'checkmark-outline' : 'copy-outline'"
        size="14"
      />
    </button>
  </div>
</template>
