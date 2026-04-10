/* eslint-disable no-param-reassign */
const STORAGE_KEY = 'chatwoot-bubble-position';
const DRAG_THRESHOLD = 5;

const getStoredPosition = () => {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : null;
  } catch (e) {
    return null;
  }
};

const storePosition = (left, top) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ left, top }));
  } catch (e) {
    // ignore
  }
};

const clampToViewport = (left, top, width, height) => {
  const maxLeft = window.innerWidth - width;
  const maxTop = window.innerHeight - height;
  return {
    left: Math.max(0, Math.min(left, maxLeft)),
    top: Math.max(0, Math.min(top, maxTop)),
  };
};

const getBubbleButtons = bubbleHolder =>
  bubbleHolder.querySelectorAll('.woot-widget-bubble');

const getCurrentRect = bubbleHolder => {
  const button = bubbleHolder.querySelector(
    '.woot-widget-bubble:not(.woot--hide)'
  );
  if (button) return button.getBoundingClientRect();
  const fallback = bubbleHolder.querySelector('.woot-widget-bubble');
  if (fallback) return fallback.getBoundingClientRect();
  return { left: 0, top: 0, width: 64, height: 64 };
};

const applyPosition = (bubbleHolder, left, top) => {
  const buttons = getBubbleButtons(bubbleHolder);
  buttons.forEach(el => {
    el.style.left = `${left}px`;
    el.style.top = `${top}px`;
    el.style.right = 'auto';
    el.style.bottom = 'auto';
  });
};

const restoreBubblePosition = bubbleHolder => {
  const stored = getStoredPosition();
  if (!stored) return;
  const rect = getCurrentRect(bubbleHolder);
  const width = rect.width || 64;
  const height = rect.height || 64;
  const { left, top } = clampToViewport(stored.left, stored.top, width, height);
  applyPosition(bubbleHolder, left, top);
};

export const enableBubbleDrag = bubbleHolder => {
  if (!bubbleHolder) return;

  let isPointerDown = false;
  let startX = 0;
  let startY = 0;
  let initialLeft = 0;
  let initialTop = 0;
  let didDrag = false;

  // Wait for buttons to be added before restoring position
  const tryRestore = () => {
    if (bubbleHolder.querySelector('.woot-widget-bubble')) {
      restoreBubblePosition(bubbleHolder);
    } else {
      setTimeout(tryRestore, 100);
    }
  };
  setTimeout(tryRestore, 0);

  const onMouseDown = event => {
    isPointerDown = true;
    didDrag = false;
    startX = event.clientX;
    startY = event.clientY;
    const rect = getCurrentRect(bubbleHolder);
    initialLeft = rect.left;
    initialTop = rect.top;
  };

  const onMouseMove = event => {
    if (!isPointerDown) return;
    const dx = event.clientX - startX;
    const dy = event.clientY - startY;

    if (!didDrag && Math.hypot(dx, dy) < DRAG_THRESHOLD) return;

    didDrag = true;
    bubbleHolder.classList.add('woot--dragging');

    const rect = getCurrentRect(bubbleHolder);
    const { left, top } = clampToViewport(
      initialLeft + dx,
      initialTop + dy,
      rect.width,
      rect.height
    );
    applyPosition(bubbleHolder, left, top);
  };

  const onMouseUp = () => {
    if (!isPointerDown) return;
    isPointerDown = false;
    bubbleHolder.classList.remove('woot--dragging');

    if (didDrag) {
      const rect = getCurrentRect(bubbleHolder);
      storePosition(rect.left, rect.top);
    }
  };

  // Use capture phase only on click to swallow it after a drag
  const onClickCapture = event => {
    if (didDrag) {
      event.stopPropagation();
      event.preventDefault();
      didDrag = false;
    }
  };

  bubbleHolder.addEventListener('mousedown', onMouseDown);
  document.addEventListener('mousemove', onMouseMove);
  document.addEventListener('mouseup', onMouseUp);
  bubbleHolder.addEventListener('click', onClickCapture, true);

  window.addEventListener('resize', () => {
    const stored = getStoredPosition();
    if (!stored) return;
    const rect = getCurrentRect(bubbleHolder);
    const { left, top } = clampToViewport(
      stored.left,
      stored.top,
      rect.width,
      rect.height
    );
    applyPosition(bubbleHolder, left, top);
  });
};
