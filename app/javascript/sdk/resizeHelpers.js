/* eslint-disable no-param-reassign */
const SIZE_STORAGE_KEY = 'chatwoot-chat-size';
const MIN_WIDTH = 320;
const MIN_HEIGHT = 400;
const MOBILE_BREAKPOINT = 667;
const BUBBLE_GAP = 16;

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

const isMobile = () => window.innerWidth < MOBILE_BREAKPOINT;

const clampSizeToQuadrant = (width, height, quadrant, bubbleRect) => {
  let maxWidth;
  let maxHeight;

  if (quadrant === 'top-left' || quadrant === 'bottom-left') {
    maxWidth = window.innerWidth - bubbleRect.left - 8;
  } else {
    maxWidth = bubbleRect.right - 8;
  }

  if (quadrant === 'top-left' || quadrant === 'top-right') {
    maxHeight = window.innerHeight - bubbleRect.bottom - BUBBLE_GAP - 8;
  } else {
    maxHeight = bubbleRect.top - BUBBLE_GAP - 8;
  }

  return {
    width: Math.max(MIN_WIDTH, Math.min(width, Math.max(MIN_WIDTH, maxWidth))),
    height: Math.max(
      MIN_HEIGHT,
      Math.min(height, Math.max(MIN_HEIGHT, maxHeight))
    ),
  };
};

const applySize = (holder, width, height) => {
  holder.style.setProperty('width', `${width}px`, 'important');
  holder.style.setProperty('height', `${height}px`, 'important');
  holder.style.setProperty('max-height', `${height}px`, 'important');
  holder.style.setProperty('min-height', `${MIN_HEIGHT}px`, 'important');
};

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

const QUADRANT_CONFIG = {
  'bottom-right': {
    transformOrigin: 'bottom right',
    handleCorner: 'top-left',
    signX: -1,
    signY: -1,
  },
  'bottom-left': {
    transformOrigin: 'bottom left',
    handleCorner: 'top-right',
    signX: 1,
    signY: -1,
  },
  'top-right': {
    transformOrigin: 'top right',
    handleCorner: 'bottom-left',
    signX: -1,
    signY: 1,
  },
  'top-left': {
    transformOrigin: 'top left',
    handleCorner: 'bottom-right',
    signX: 1,
    signY: 1,
  },
};

const applyChatPosition = (holder, bubbleRect, quadrant) => {
  // Reset all anchor properties
  holder.style.setProperty('position', 'fixed', 'important');
  holder.style.setProperty('left', 'auto', 'important');
  holder.style.setProperty('right', 'auto', 'important');
  holder.style.setProperty('top', 'auto', 'important');
  holder.style.setProperty('bottom', 'auto', 'important');

  switch (quadrant) {
    case 'bottom-right':
      holder.style.setProperty(
        'right',
        `${window.innerWidth - bubbleRect.right}px`,
        'important'
      );
      holder.style.setProperty(
        'bottom',
        `${window.innerHeight - bubbleRect.top + BUBBLE_GAP}px`,
        'important'
      );
      break;
    case 'bottom-left':
      holder.style.setProperty('left', `${bubbleRect.left}px`, 'important');
      holder.style.setProperty(
        'bottom',
        `${window.innerHeight - bubbleRect.top + BUBBLE_GAP}px`,
        'important'
      );
      break;
    case 'top-right':
      holder.style.setProperty(
        'right',
        `${window.innerWidth - bubbleRect.right}px`,
        'important'
      );
      holder.style.setProperty(
        'top',
        `${bubbleRect.bottom + BUBBLE_GAP}px`,
        'important'
      );
      break;
    case 'top-left':
      holder.style.setProperty('left', `${bubbleRect.left}px`, 'important');
      holder.style.setProperty(
        'top',
        `${bubbleRect.bottom + BUBBLE_GAP}px`,
        'important'
      );
      break;
    default:
      break;
  }

  holder.style.setProperty(
    'transform-origin',
    QUADRANT_CONFIG[quadrant].transformOrigin,
    'important'
  );
};

const removeAllHandles = holder => {
  holder.querySelectorAll('.woot-resize-handle').forEach(h => h.remove());
};

const createHandle = (holder, { className, signX, signY, resizeX, resizeY }) => {
  const handle = document.createElement('div');
  handle.className = `woot-resize-handle ${className}`;
  handle.setAttribute('aria-label', 'Resize chat');
  holder.appendChild(handle);

  let isResizing = false;
  let startX = 0;
  let startY = 0;
  let startWidth = 0;
  let startHeight = 0;
  let bubbleRect = null;
  let quadrant = null;

  const onMouseDown = event => {
    if (isMobile()) return;
    event.preventDefault();
    event.stopPropagation();
    const rect = holder.getBoundingClientRect();
    isResizing = true;
    startX = event.clientX;
    startY = event.clientY;
    startWidth = rect.width;
    startHeight = rect.height;
    quadrant = holder.dataset.wootQuadrant || 'bottom-right';
    const bubbleHolder = document.querySelector('.woot--bubble-holder');
    bubbleRect = bubbleHolder ? getBubbleRect(bubbleHolder) : null;
    holder.classList.add('woot--resizing');
  };

  const onMouseMove = event => {
    if (!isResizing) return;
    event.preventDefault();
    const dx = (event.clientX - startX) * signX;
    const dy = (event.clientY - startY) * signY;
    const newWidth = resizeX ? startWidth + dx : startWidth;
    const newHeight = resizeY ? startHeight + dy : startHeight;
    const clamped = bubbleRect
      ? clampSizeToQuadrant(newWidth, newHeight, quadrant, bubbleRect)
      : { width: newWidth, height: newHeight };
    applySize(holder, clamped.width, clamped.height);
  };

  const onMouseUp = () => {
    if (!isResizing) return;
    isResizing = false;
    holder.classList.remove('woot--resizing');
    const rect = holder.getBoundingClientRect();
    storeSize(rect.width, rect.height);
  };

  handle.addEventListener('mousedown', onMouseDown);
  document.addEventListener('mousemove', onMouseMove);
  document.addEventListener('mouseup', onMouseUp);
};

const recreateHandlesForQuadrant = (holder, quadrant) => {
  removeAllHandles(holder);
  const { signX, signY, handleCorner } = QUADRANT_CONFIG[quadrant];

  // Corner handle (free resize in both axes)
  createHandle(holder, {
    className: `woot-resize-handle--corner woot-resize-handle--corner-${handleCorner}`,
    signX,
    signY,
    resizeX: true,
    resizeY: true,
  });

  // Edge handle for vertical resize (top or bottom edge)
  const isTopEdge = handleCorner.startsWith('top');
  createHandle(holder, {
    className: isTopEdge
      ? 'woot-resize-handle--top'
      : 'woot-resize-handle--bottom',
    signX: 1,
    signY,
    resizeX: false,
    resizeY: true,
  });

  // Edge handle for horizontal resize (left or right edge)
  const isLeftEdge = handleCorner.endsWith('left');
  createHandle(holder, {
    className: isLeftEdge
      ? 'woot-resize-handle--left'
      : 'woot-resize-handle--right',
    signX,
    signY: 1,
    resizeX: true,
    resizeY: false,
  });
};

export const positionChatBasedOnBubble = (holder, bubbleHolder) => {
  if (!holder || !bubbleHolder) return;
  if (isMobile()) {
    holder.style.cssText = '';
    removeAllHandles(holder);
    return;
  }

  const bubbleRect = getBubbleRect(bubbleHolder);
  if (!bubbleRect) return;

  const quadrant = getQuadrant(bubbleRect);
  holder.dataset.wootQuadrant = quadrant;

  applyChatPosition(holder, bubbleRect, quadrant);

  // Apply stored size, clamped to quadrant available space
  const stored = getStoredSize() || { width: 400, height: 600 };
  const { width, height } = clampSizeToQuadrant(
    stored.width,
    stored.height,
    quadrant,
    bubbleRect
  );
  applySize(holder, width, height);

  recreateHandlesForQuadrant(holder, quadrant);
};

export const enableChatResize = holder => {
  if (!holder) return;

  // Initial setup: handles will be created when chat first opens
  // via positionChatBasedOnBubble. Window resize triggers recalculation.
  window.addEventListener('resize', () => {
    if (isMobile()) {
      holder.style.cssText = '';
      removeAllHandles(holder);
      return;
    }
    if (!window.$chatwoot || !window.$chatwoot.isOpen) return;
    const bubbleHolder = document.querySelector('.woot--bubble-holder');
    if (bubbleHolder) positionChatBasedOnBubble(holder, bubbleHolder);
  });
};
