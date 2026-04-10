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

const applyPosition = (element, left, top) => {
  element.style.position = 'fixed';
  element.style.left = `${left}px`;
  element.style.top = `${top}px`;
  element.style.right = 'auto';
  element.style.bottom = 'auto';
};

export const restoreBubblePosition = bubbleHolder => {
  const stored = getStoredPosition();
  if (!stored) return;

  const rect = bubbleHolder.getBoundingClientRect();
  const width = rect.width || 64;
  const height = rect.height || 64;
  const { left, top } = clampToViewport(stored.left, stored.top, width, height);
  applyPosition(bubbleHolder, left, top);
};

export const enableBubbleDrag = bubbleHolder => {
  if (!bubbleHolder) return;

  let isDragging = false;
  let startX = 0;
  let startY = 0;
  let initialLeft = 0;
  let initialTop = 0;
  let moved = false;

  restoreBubblePosition(bubbleHolder);

  const getEventPoint = event => {
    if (event.touches && event.touches.length > 0) {
      return { x: event.touches[0].clientX, y: event.touches[0].clientY };
    }
    return { x: event.clientX, y: event.clientY };
  };

  const onPointerDown = event => {
    const point = getEventPoint(event);
    const rect = bubbleHolder.getBoundingClientRect();
    isDragging = true;
    moved = false;
    startX = point.x;
    startY = point.y;
    initialLeft = rect.left;
    initialTop = rect.top;
    bubbleHolder.classList.add('woot--dragging');
  };

  const onPointerMove = event => {
    if (!isDragging) return;
    const point = getEventPoint(event);
    const dx = point.x - startX;
    const dy = point.y - startY;

    if (!moved && Math.hypot(dx, dy) < DRAG_THRESHOLD) return;

    moved = true;
    if (event.cancelable) event.preventDefault();

    const rect = bubbleHolder.getBoundingClientRect();
    const { left, top } = clampToViewport(
      initialLeft + dx,
      initialTop + dy,
      rect.width,
      rect.height
    );
    applyPosition(bubbleHolder, left, top);
  };

  const onPointerUp = event => {
    if (!isDragging) return;
    isDragging = false;
    bubbleHolder.classList.remove('woot--dragging');

    if (moved) {
      const rect = bubbleHolder.getBoundingClientRect();
      storePosition(rect.left, rect.top);
      // Prevent the click that follows the drag from opening the chat
      const stopClick = e => {
        e.stopPropagation();
        e.preventDefault();
        bubbleHolder.removeEventListener('click', stopClick, true);
      };
      bubbleHolder.addEventListener('click', stopClick, true);
    }
  };

  bubbleHolder.addEventListener('mousedown', onPointerDown);
  document.addEventListener('mousemove', onPointerMove);
  document.addEventListener('mouseup', onPointerUp);

  bubbleHolder.addEventListener('touchstart', onPointerDown, { passive: true });
  document.addEventListener('touchmove', onPointerMove, { passive: false });
  document.addEventListener('touchend', onPointerUp);

  window.addEventListener('resize', () => {
    const stored = getStoredPosition();
    if (!stored) return;
    const rect = bubbleHolder.getBoundingClientRect();
    const { left, top } = clampToViewport(
      stored.left,
      stored.top,
      rect.width,
      rect.height
    );
    applyPosition(bubbleHolder, left, top);
  });
};
