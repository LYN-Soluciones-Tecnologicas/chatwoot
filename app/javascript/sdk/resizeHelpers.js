/* eslint-disable no-param-reassign */
const STORAGE_KEY = 'chatwoot-chat-size';
const MIN_WIDTH = 320;
const MIN_HEIGHT = 400;
const MOBILE_BREAKPOINT = 667;

const getStoredSize = () => {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : null;
  } catch (e) {
    return null;
  }
};

const storeSize = (width, height) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ width, height }));
  } catch (e) {
    // ignore
  }
};

const isMobile = () => window.innerWidth < MOBILE_BREAKPOINT;

const clampSize = (width, height) => ({
  width: Math.max(MIN_WIDTH, Math.min(width, window.innerWidth * 0.9)),
  height: Math.max(MIN_HEIGHT, Math.min(height, window.innerHeight * 0.9)),
});

const applySize = (holder, width, height) => {
  holder.style.width = `${width}px`;
  holder.style.height = `${height}px`;
  holder.style.maxHeight = `${height}px`;
};

export const restoreChatSize = holder => {
  if (!holder || isMobile()) return;
  const stored = getStoredSize();
  if (!stored) return;
  const { width, height } = clampSize(stored.width, stored.height);
  applySize(holder, width, height);
};

export const enableChatResize = holder => {
  if (!holder) return;

  // Create resize handle
  const handle = document.createElement('div');
  handle.className = 'woot-resize-handle';
  handle.setAttribute('aria-label', 'Resize chat');
  holder.appendChild(handle);

  let isResizing = false;
  let startX = 0;
  let startY = 0;
  let startWidth = 0;
  let startHeight = 0;

  restoreChatSize(holder);

  const getEventPoint = event => {
    if (event.touches && event.touches.length > 0) {
      return { x: event.touches[0].clientX, y: event.touches[0].clientY };
    }
    return { x: event.clientX, y: event.clientY };
  };

  const onPointerDown = event => {
    if (isMobile()) return;
    if (event.cancelable) event.preventDefault();
    event.stopPropagation();
    const point = getEventPoint(event);
    const rect = holder.getBoundingClientRect();
    isResizing = true;
    startX = point.x;
    startY = point.y;
    startWidth = rect.width;
    startHeight = rect.height;
    holder.classList.add('woot--resizing');
  };

  const onPointerMove = event => {
    if (!isResizing) return;
    if (event.cancelable) event.preventDefault();
    const point = getEventPoint(event);
    // Top-left handle: dragging up/left makes it bigger
    const dx = startX - point.x;
    const dy = startY - point.y;
    const { width, height } = clampSize(startWidth + dx, startHeight + dy);
    applySize(holder, width, height);
  };

  const onPointerUp = () => {
    if (!isResizing) return;
    isResizing = false;
    holder.classList.remove('woot--resizing');
    const rect = holder.getBoundingClientRect();
    storeSize(rect.width, rect.height);
  };

  handle.addEventListener('mousedown', onPointerDown);
  document.addEventListener('mousemove', onPointerMove);
  document.addEventListener('mouseup', onPointerUp);

  handle.addEventListener('touchstart', onPointerDown, { passive: false });
  document.addEventListener('touchmove', onPointerMove, { passive: false });
  document.addEventListener('touchend', onPointerUp);

  window.addEventListener('resize', () => {
    if (isMobile()) {
      holder.style.width = '';
      holder.style.height = '';
      holder.style.maxHeight = '';
      return;
    }
    restoreChatSize(holder);
  });
};
