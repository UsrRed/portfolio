<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'

const props = defineProps<{ file: File; aspect: number }>()
const emit = defineEmits<{ confirm: [File]; skip: []; cancel: [] }>()

const imgSrc = URL.createObjectURL(props.file)
const imgEl = ref<HTMLImageElement>()
const ready = ref(false)
const processing = ref(false)

// Crop en pixels affichés, relatif à l'image
const crop = reactive({ x: 0, y: 0, w: 0, h: 0 })
const MIN = 32

const aspectLabel = computed(() => {
  const known: [number, string][] = [
    [1, '1:1'], [4 / 5, '4:5'], [5 / 4, '5:4'], [16 / 9, '16:9'],
    [9 / 16, '9:16'], [4 / 3, '4:3'], [3 / 4, '3:4'], [3 / 2, '3:2'], [11 / 8, '11:8'],
  ]
  const hit = known.find(([r]) => Math.abs(r - props.aspect) < 0.01)
  return hit ? hit[1] : props.aspect.toFixed(2)
})

function dispSize() {
  const img = imgEl.value!
  return { W: img.clientWidth, H: img.clientHeight }
}

function onImgLoad() {
  const { W, H } = dispSize()
  let w = W
  let h = w / props.aspect
  if (h > H) {
    h = H
    w = h * props.aspect
  }
  crop.w = w
  crop.h = h
  crop.x = (W - w) / 2
  crop.y = (H - h) / 2
  ready.value = true
}

const boxStyle = computed(() => ({
  left: `${crop.x}px`,
  top: `${crop.y}px`,
  width: `${crop.w}px`,
  height: `${crop.h}px`,
}))

// ── Drag / resize ────────────────────────────────────────────────────────────

type Corner = 'nw' | 'ne' | 'sw' | 'se'
const corners: Corner[] = ['nw', 'ne', 'sw', 'se']

let mode: 'drag' | Corner | null = null
let start = { px: 0, py: 0, x: 0, y: 0 }
let anchor = { x: 0, y: 0 }

function pointerPos(e: PointerEvent) {
  const r = imgEl.value!.getBoundingClientRect()
  return { px: e.clientX - r.left, py: e.clientY - r.top }
}

function startDrag(e: PointerEvent) {
  mode = 'drag'
  const p = pointerPos(e)
  start = { ...p, x: crop.x, y: crop.y }
  bindWindow()
}

function startResize(_e: PointerEvent, c: Corner) {
  mode = c
  anchor = {
    x: c === 'nw' || c === 'sw' ? crop.x + crop.w : crop.x,
    y: c === 'nw' || c === 'ne' ? crop.y + crop.h : crop.y,
  }
  bindWindow()
}

function onMove(e: PointerEvent) {
  if (!mode) return
  e.preventDefault()
  const { W, H } = dispSize()
  const p = pointerPos(e)

  if (mode === 'drag') {
    crop.x = Math.min(Math.max(start.x + p.px - start.px, 0), W - crop.w)
    crop.y = Math.min(Math.max(start.y + p.py - start.py, 0), H - crop.h)
    return
  }

  const left = mode === 'nw' || mode === 'sw'
  const up = mode === 'nw' || mode === 'ne'
  const wp = left ? anchor.x - p.px : p.px - anchor.x
  const hp = up ? anchor.y - p.py : p.py - anchor.y
  const maxW = Math.min(left ? anchor.x : W - anchor.x, (up ? anchor.y : H - anchor.y) * props.aspect)
  const w = Math.min(Math.max(Math.max(wp, hp * props.aspect), Math.min(MIN, maxW)), maxW)
  crop.w = w
  crop.h = w / props.aspect
  crop.x = left ? anchor.x - w : anchor.x
  crop.y = up ? anchor.y - crop.h : anchor.y
}

function onUp() {
  mode = null
  unbindWindow()
}

function bindWindow() {
  window.addEventListener('pointermove', onMove)
  window.addEventListener('pointerup', onUp)
}

function unbindWindow() {
  window.removeEventListener('pointermove', onMove)
  window.removeEventListener('pointerup', onUp)
}

function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape') emit('cancel')
}

onMounted(() => window.addEventListener('keydown', onKey))
onBeforeUnmount(() => {
  unbindWindow()
  window.removeEventListener('keydown', onKey)
  URL.revokeObjectURL(imgSrc)
})

// ── Export ───────────────────────────────────────────────────────────────────

function outName(type: string) {
  const base = props.file.name.replace(/\.[^.]+$/, '') || 'image'
  return `${base}${type === 'image/jpeg' ? '.jpg' : '.png'}`
}

function confirmCrop() {
  if (processing.value || !ready.value) return
  processing.value = true
  const img = imgEl.value!
  const scale = img.naturalWidth / img.clientWidth
  const sx = crop.x * scale
  const sy = crop.y * scale
  const sw = Math.max(1, crop.w * scale)
  const sh = Math.max(1, crop.h * scale)

  const MAX = 1600
  let ow = Math.round(sw)
  let oh = Math.round(sh)
  if (Math.max(ow, oh) > MAX) {
    const k = MAX / Math.max(ow, oh)
    ow = Math.max(1, Math.round(ow * k))
    oh = Math.max(1, Math.round(oh * k))
  }

  const canvas = document.createElement('canvas')
  canvas.width = ow
  canvas.height = oh
  canvas.getContext('2d')!.drawImage(img, sx, sy, sw, sh, 0, 0, ow, oh)

  const type = props.file.type === 'image/jpeg' ? 'image/jpeg' : 'image/png'
  canvas.toBlob(
    blob => {
      processing.value = false
      if (!blob) return emit('skip')
      emit('confirm', new File([blob], outName(type), { type }))
    },
    type,
    0.92,
  )
}
</script>

<template>
  <Teleport to="body">
    <div class="crop-overlay" @click.self="emit('cancel')">
      <div class="crop-modal">
        <h3 class="crop-title">Recadrer l'image <span class="crop-ratio">{{ aspectLabel }}</span></h3>
        <div class="crop-stage">
          <div class="crop-wrap">
            <img ref="imgEl" :src="imgSrc" alt="à recadrer" draggable="false" @load="onImgLoad" />
            <div v-if="ready" class="crop-box" :style="boxStyle" @pointerdown.prevent="startDrag">
              <div
                v-for="c in corners"
                :key="c"
                class="handle"
                :class="c"
                @pointerdown.prevent.stop="startResize($event, c)"
              />
            </div>
          </div>
        </div>
        <div class="crop-actions">
          <button type="button" class="crop-btn" @click="emit('cancel')">Annuler</button>
          <button type="button" class="crop-btn" @click="emit('skip')">Utiliser tel quel</button>
          <button type="button" class="crop-btn primary" :disabled="processing" @click="confirmCrop">
            {{ processing ? '…' : 'Recadrer' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.crop-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  -webkit-backdrop-filter: blur(4px);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1100;
  padding: 1rem;
}

.crop-modal {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 1rem;
  max-width: min(92vw, 720px);
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.crop-title {
  margin: 0;
  font-size: 1rem;
  color: var(--text);
}

.crop-ratio {
  color: var(--primary);
  font-size: 0.85rem;
  margin-left: 0.5rem;
}

.crop-stage {
  display: flex;
  justify-content: center;
}

.crop-wrap {
  position: relative;
  display: inline-block;
  overflow: hidden;
  line-height: 0;
  /* damier pour visualiser la transparence */
  background-image: conic-gradient(rgba(128, 128, 128, 0.2) 0 25%, transparent 0 50%, rgba(128, 128, 128, 0.2) 0 75%, transparent 0);
  background-size: 16px 16px;
}

.crop-wrap img {
  max-width: min(84vw, 640px);
  max-height: 60vh;
  display: block;
  user-select: none;
  -webkit-user-drag: none;
}

.crop-box {
  position: absolute;
  box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.55);
  border: 1.5px solid var(--primary);
  cursor: move;
  touch-action: none;
  /* règle des tiers */
  background-image:
    linear-gradient(to right, transparent calc(33.33% - 0.5px), rgba(255, 255, 255, 0.25) 33.33%, transparent calc(33.33% + 0.5px), transparent calc(66.66% - 0.5px), rgba(255, 255, 255, 0.25) 66.66%, transparent calc(66.66% + 0.5px)),
    linear-gradient(to bottom, transparent calc(33.33% - 0.5px), rgba(255, 255, 255, 0.25) 33.33%, transparent calc(33.33% + 0.5px), transparent calc(66.66% - 0.5px), rgba(255, 255, 255, 0.25) 66.66%, transparent calc(66.66% + 0.5px));
}

.handle {
  position: absolute;
  width: 14px;
  height: 14px;
  background: var(--primary);
  border-radius: 50%;
  touch-action: none;
}

.handle.nw { top: -7px; left: -7px; cursor: nwse-resize; }
.handle.se { bottom: -7px; right: -7px; cursor: nwse-resize; }
.handle.ne { top: -7px; right: -7px; cursor: nesw-resize; }
.handle.sw { bottom: -7px; left: -7px; cursor: nesw-resize; }

.crop-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}

.crop-btn {
  padding: 0.5rem 0.875rem;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text);
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.crop-btn:hover {
  border-color: var(--primary);
}

.crop-btn.primary {
  background: var(--primary-dim);
  border-color: rgba(var(--primary-rgb), 0.3);
  color: var(--primary);
}

.crop-btn.primary:hover:not(:disabled) {
  background: rgba(var(--primary-rgb), 0.2);
}

.crop-btn:disabled {
  opacity: 0.7;
  cursor: default;
}
</style>
