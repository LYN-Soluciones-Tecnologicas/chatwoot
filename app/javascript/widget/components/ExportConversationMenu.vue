<script>
import { mapGetters } from 'vuex';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import configMixin from 'widget/mixins/configMixin';
import { exportConversation } from 'widget/api/conversation';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

export default {
  name: 'ExportConversationMenu',
  components: { FluentIcon },
  mixins: [configMixin],
  data() {
    return {
      isOpen: false,
      isExporting: false,
    };
  },
  computed: {
    ...mapGetters({
      conversationSize: 'conversation/getConversationSize',
    }),
    shouldRender() {
      return this.hasExportConversationEnabled && this.conversationSize > 0;
    },
  },
  mounted() {
    document.addEventListener('click', this.handleOutsideClick);
  },
  beforeUnmount() {
    document.removeEventListener('click', this.handleOutsideClick);
  },
  methods: {
    toggleMenu() {
      this.isOpen = !this.isOpen;
    },
    closeMenu() {
      this.isOpen = false;
    },
    handleOutsideClick(event) {
      if (!this.$el.contains(event.target)) {
        this.closeMenu();
      }
    },
    async handleExport(format) {
      if (this.isExporting) return;
      this.isExporting = true;
      this.closeMenu();
      try {
        await exportConversation(format);
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('EXPORT_CONVERSATION.SUCCESS'),
          type: 'success',
        });
      } catch (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('EXPORT_CONVERSATION.ERROR'),
        });
      } finally {
        this.isExporting = false;
      }
    },
  },
};
</script>

<template>
  <div v-if="shouldRender" class="relative">
    <button
      class="button transparent compact"
      :title="$t('EXPORT_CONVERSATION.MENU_LABEL')"
      :disabled="isExporting"
      @click.stop="toggleMenu"
    >
      <FluentIcon icon="arrow-download" size="22" class="text-n-slate-12" />
    </button>
    <div
      v-if="isOpen"
      class="absolute right-0 top-10 z-50 min-w-[200px] rounded-md bg-white dark:bg-n-solid-2 shadow-lg border border-n-weak py-1"
    >
      <button
        class="w-full text-left px-4 py-2 text-sm text-n-slate-12 hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
        @click="handleExport('pdf')"
      >
        {{ $t('EXPORT_CONVERSATION.FORMAT_PDF') }}
      </button>
      <button
        class="w-full text-left px-4 py-2 text-sm text-n-slate-12 hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
        @click="handleExport('docx')"
      >
        {{ $t('EXPORT_CONVERSATION.FORMAT_DOCX') }}
      </button>
      <button
        class="w-full text-left px-4 py-2 text-sm text-n-slate-12 hover:bg-n-slate-2 dark:hover:bg-n-solid-3"
        @click="handleExport('odt')"
      >
        {{ $t('EXPORT_CONVERSATION.FORMAT_ODT') }}
      </button>
    </div>
  </div>
</template>
