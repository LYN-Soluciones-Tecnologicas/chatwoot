<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['confirm', 'cancel']);

const { t } = useI18n();
</script>

<template>
  <transition name="dialog-fade">
    <div
      v-if="show"
      class="absolute inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      role="dialog"
      aria-modal="true"
      @click.self="emit('cancel')"
    >
      <div
        class="w-full max-w-xs rounded-xl bg-n-background p-5 shadow-lg dark:bg-n-solid-2"
      >
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('END_CONVERSATION_DIALOG.TITLE') }}
        </h3>
        <p class="mt-2 text-sm leading-5 text-n-slate-11">
          {{ t('END_CONVERSATION_DIALOG.DESCRIPTION') }}
        </p>
        <div class="flex justify-end gap-2 mt-5">
          <button
            type="button"
            class="rounded-md px-3 py-1.5 text-sm font-medium text-n-slate-12 transition-colors hover:bg-n-slate-3"
            @click="emit('cancel')"
          >
            {{ t('END_CONVERSATION_DIALOG.CANCEL') }}
          </button>
          <button
            type="button"
            class="rounded-md bg-n-ruby-9 px-3 py-1.5 text-sm font-medium text-white transition-colors hover:bg-n-ruby-10"
            @click="emit('confirm')"
          >
            {{ t('END_CONVERSATION_DIALOG.CONFIRM') }}
          </button>
        </div>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.dialog-fade-enter-active,
.dialog-fade-leave-active {
  transition: opacity 0.15s ease;
}
.dialog-fade-enter-from,
.dialog-fade-leave-to {
  opacity: 0;
}
</style>
