/* eslint-disable no-param-reassign */
import { MOBILE_BREAKPOINT } from './constants';

const SIZE_STORAGE_KEY = 'chatwoot-chat-size';
const MIN_WIDTH = 320;
const MIN_HEIGHT = 400;
const BUBBLE_GAP = 16;
const VIEWPORT_PADDING = 8;

const getStoredSize = () => {
  try {
    const data = localStorage.getItem(SIZE_STORAGE_KEY);
    return data ? JSON.parse(data) : null;
  } catch (e) {
    return null;
  }
};

const storeSize = (width, height) => {
  try {
    localStorage.setItem(SIZE_STORAGE_KEY, JSON.stringify({ width, height }));
  } catch (e) {
    // ignore
  }
};

export const isMobileViewport = () =>
  window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT}px)`).matches;

const getBubbleRect = bubbleHolder => {
  const button = bubbleHolder.querySelector(
    '.woot-widget-bubble:not(.woot--hide)'
  );
  if (button) return button.getBoundingClientRect();
  const fallback = bubbleHolder.querySelector('.woot-widget-bubble');
  if (fallback) return fallback.getBoundingClientRect();
  return null;
};

const getQuadrant = bubbleRect => {
  const centerX = bubbleRect.left + bubbleRect.width / 2;
  const centerY = bubbleRect.top + bubbleRect.height / 2;
  const isLeft = centerX < window.innerWidth / 2;
  const isTop = centerY < window.innerHeight / 2;
  if (isTop && isLeft) return 'top-left';
  if (isTop && !isLeft) return 'top-right';
  if (!isTop && isLeft) return 'bottom-left';
  return 'bottom-right';
};

const QUADRANT_TRANSFORM_ORIGIN = {
  'bottom-right': 'bottom right',
  'bottom-left': 'bottom left',
  'top-right': 'top right',
  'top-left': 'top left',
};

/**
 * Compute initial chat box (left, top, width, height) based on bubble quadrant
 */
const computeInitialBox = (
  bubbleRect,
  quadrant,
  desiredWidth,
  desiredHeight
) => {
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  let left;
  let top;
  let width = desiredWidth;
  let height = desiredHeight;

  switch (quadrant) {
    case 'bottom-right':
      width = Math.min(width, bubbleRect.right - VIEWPORT_PADDING);
      height = Math.min(height, bubbleRect.top - BUBBLE_GAP - VIEWPORT_PADDING);
      left = bubbleRect.right - width;
      top = bubbleRect.top - BUBBLE_GAP - height;
      break;
    case 'bottom-left':
      width = Math.min(width, vw - bubbleRect.left - VIEWPORT_PADDING);
      height = Math.min(height, bubbleRect.top - BUBBLE_GAP - VIEWPORT_PADDING);
      left = bubbleRect.left;
      top = bubbleRect.top - BUBBLE_GAP - height;
      break;
    case 'top-right':
      width = Math.min(width, bubbleRect.right - VIEWPORT_PADDING);
      height = Math.min(
        height,
        vh - bubbleRect.bottom - BUBBLE_GAP - VIEWPORT_PADDING
      );
      left = bubbleRect.right - width;
      top = bubbleRect.bottom + BUBBLE_GAP;
      break;
    case 'top-left':
    default:
      width = Math.min(width, vw - bubbleRect.left - VIEWPORT_PADDING);
      height = Math.min(
        height,
        vh - bubbleRect.bottom - BUBBLE_GAP - VIEWPORT_PADDING
      );
      left = bubbleRect.left;
      top = bubbleRect.bottom + BUBBLE_GAP;
      break;
  }

  width = Math.max(MIN_WIDTH, width);
  height = Math.max(MIN_HEIGHT, height);
  return { left, top, width, height };
};

const applyBox = (holder, box) => {
  holder.style.removeProperty('border-radius');
  holder.style.setProperty('position', 'fixed', 'important');
  holder.style.setProperty('left', `${box.left}px`, 'important');
  holder.style.setProperty('top', `${box.top}px`, 'important');
  holder.style.setProperty('right', 'auto', 'important');
  holder.style.setProperty('bottom', 'auto', 'important');
  holder.style.setProperty('width', `${box.width}px`, 'important');
  holder.style.setProperty('height', `${box.height}px`, 'important');
  holder.style.setProperty('max-height', `${box.height}px`, 'important');
  holder.style.setProperty('min-height', `${MIN_HEIGHT}px`, 'important');
};

const applyFullscreenBox = holder => {
  holder.style.setProperty('position', 'fixed', 'important');
  holder.style.setProperty('left', '0', 'important');
  holder.style.setProperty('top', '0', 'important');
  holder.style.setProperty('right', '0', 'important');
  holder.style.setProperty('bottom', '0', 'important');
  holder.style.setProperty('width', '100%', 'important');
  holder.style.setProperty('height', '100%', 'important');
  holder.style.setProperty('max-height', '100vh', 'important');
  holder.style.setProperty('min-height', '100%', 'important');
  holder.style.setProperty('border-radius', '0', 'important');
  holder.style.setProperty('transform-origin', 'center', 'important');
};

const removeAllHandles = holder => {
  holder.querySelectorAll('.woot-resize-handle').forEach(h => h.remove());
};

const HANDLE_DEFINITIONS = [
  { name: 'top', edges: { top: true }, cursor: 'ns-resize' },
  { name: 'bottom', edges: { bottom: true }, cursor: 'ns-resize' },
  { name: 'left', edges: { left: true }, cursor: 'ew-resize' },
  { name: 'right', edges: { right: true }, cursor: 'ew-resize' },
  {
    name: 'corner-top-left',
    edges: { top: true, left: true },
    cursor: 'nwse-resize',
  },
  {
    name: 'corner-top-right',
    edges: { top: true, right: true },
    cursor: 'nesw-resize',
  },
  {
    name: 'corner-bottom-left',
    edges: { bottom: true, left: true },
    cursor: 'nesw-resize',
  },
  {
    name: 'corner-bottom-right',
    edges: { bottom: true, right: true },
    cursor: 'nwse-resize',
  },
];

const createHandle = (holder, definition) => {
  const handle = document.createElement('div');
  handle.className = `woot-resize-handle woot-resize-handle--${definition.name}`;
  handle.setAttribute('aria-label', 'Resize chat');
  holder.appendChild(handle);

  let isResizing = false;
  let startX = 0;
  let startY = 0;
  let startBox = null;

  const onMouseDown = event => {
    if (isMobileViewport()) return;
    event.preventDefault();
    event.stopPropagation();
    const rect = holder.getBoundingClientRect();
    isResizing = true;
    startX = event.clientX;
    startY = event.clientY;
    startBox = {
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
    };
    holder.classList.add('woot--resizing');

    // Disable iframe pointer events so mousemove keeps reaching document
    const iframe = document.getElementById('chatwoot_live_chat_widget');
    if (iframe) iframe.style.pointerEvents = 'none';

    // Lock cursor and prevent text selection during resize
    document.body.style.cursor = definition.cursor;
    document.body.style.userSelect = 'none';
  };

  const onMouseMove = event => {
    if (!isResizing) return;
    event.preventDefault();
    const dx = event.clientX - startX;
    const dy = event.clientY - startY;

    let { left, top, width, height } = startBox;
    const { edges } = definition;

    if (edges.right) {
      width = startBox.width + dx;
    }
    if (edges.left) {
      width = startBox.width - dx;
      left = startBox.left + dx;
    }
    if (edges.bottom) {
      height = startBox.height + dy;
    }
    if (edges.top) {
      height = startBox.height - dy;
      top = startBox.top + dy;
    }

    // Enforce min size and adjust position to keep opposite edge fixed
    if (width < MIN_WIDTH) {
      if (edges.left) left = startBox.left + (startBox.width - MIN_WIDTH);
      width = MIN_WIDTH;
    }
    if (height < MIN_HEIGHT) {
      if (edges.top) top = startBox.top + (startBox.height - MIN_HEIGHT);
      height = MIN_HEIGHT;
    }

    // Clamp to viewport
    if (left < VIEWPORT_PADDING) {
      width = Math.max(MIN_WIDTH, width + (left - VIEWPORT_PADDING));
      left = VIEWPORT_PADDING;
    }
    if (top < VIEWPORT_PADDING) {
      height = Math.max(MIN_HEIGHT, height + (top - VIEWPORT_PADDING));
      top = VIEWPORT_PADDING;
    }
    if (left + width > window.innerWidth - VIEWPORT_PADDING) {
      width = Math.max(MIN_WIDTH, window.innerWidth - VIEWPORT_PADDING - left);
    }
    if (top + height > window.innerHeight - VIEWPORT_PADDING) {
      height = Math.max(
        MIN_HEIGHT,
        window.innerHeight - VIEWPORT_PADDING - top
      );
    }

    applyBox(holder, { left, top, width, height });
  };

  const onMouseUp = () => {
    if (!isResizing) return;
    isResizing = false;
    holder.classList.remove('woot--resizing');

    // Restore iframe pointer events
    const iframe = document.getElementById('chatwoot_live_chat_widget');
    if (iframe) iframe.style.pointerEvents = '';

    // Restore body cursor and selection
    document.body.style.cursor = '';
    document.body.style.userSelect = '';

    const rect = holder.getBoundingClientRect();
    storeSize(rect.width, rect.height);
  };

  handle.addEventListener('mousedown', onMouseDown);
  document.addEventListener('mousemove', onMouseMove);
  document.addEventListener('mouseup', onMouseUp);
};

const createAllHandles = holder => {
  removeAllHandles(holder);
  HANDLE_DEFINITIONS.forEach(def => createHandle(holder, def));
};

export const positionChatBasedOnBubble = (holder, bubbleHolder) => {
  if (!holder || !bubbleHolder) return;
  if (window.$chatwoot?.isFullscreen) {
    applyFullscreenBox(holder);
    removeAllHandles(holder);
    return;
  }
  if (isMobileViewport()) {
    holder.style.cssText = '';
    removeAllHandles(holder);
    return;
  }

  const bubbleRect = getBubbleRect(bubbleHolder);
  if (!bubbleRect) return;

  const quadrant = getQuadrant(bubbleRect);
  const stored = getStoredSize() || { width: 400, height: 600 };
  const box = computeInitialBox(
    bubbleRect,
    quadrant,
    stored.width,
    stored.height
  );

  applyBox(holder, box);
  holder.style.setProperty(
    'transform-origin',
    QUADRANT_TRANSFORM_ORIGIN[quadrant],
    'important'
  );

  createAllHandles(holder);
};

export const setChatFullscreen = (holder, bubbleHolder, isFullscreen) => {
  if (!holder || !bubbleHolder) return;
  window.$chatwoot.isFullscreen = isFullscreen;

  if (isFullscreen) {
    holder.classList.add('woot-widget-holder--fullscreen');
    bubbleHolder.classList.add('woot--fullscreen');
    applyFullscreenBox(holder);
    removeAllHandles(holder);
    return;
  }

  holder.classList.remove('woot-widget-holder--fullscreen');
  bubbleHolder.classList.remove('woot--fullscreen');

  if (
    window.$chatwoot.isOpen &&
    !isMobileViewport() &&
    window.$chatwoot.resizableChat !== false
  ) {
    positionChatBasedOnBubble(holder, bubbleHolder);
  } else {
    holder.style.cssText = '';
    removeAllHandles(holder);
  }
};

export const enableChatResize = holder => {
  if (!holder) return;

  window.addEventListener('resize', () => {
    if (isMobileViewport()) {
      holder.style.cssText = '';
      removeAllHandles(holder);
      return;
    }
    if (!window.$chatwoot || !window.$chatwoot.isOpen) return;
    const bubbleHolder = document.querySelector('.woot--bubble-holder');
    if (!bubbleHolder) return;
    if (window.$chatwoot.isFullscreen) {
      setChatFullscreen(holder, bubbleHolder, true);
    } else {
      positionChatBasedOnBubble(holder, bubbleHolder);
    }
  });
};
