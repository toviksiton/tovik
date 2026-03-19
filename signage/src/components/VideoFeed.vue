<template>
  <div class="video-wrap">
    <video
      ref="videoEl"
      autoplay
      muted
      playsinline
      class="video-el"
    />
    <div v-if="streamError" class="video-error">
      <span>⚠ {{ streamError }}</span>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onUnmounted } from 'vue'

const props = defineProps({
  deviceId: { type: String, required: true },
})

const videoEl = ref(null)
const streamError = ref('')
let currentStream = null

async function startStream(deviceId) {
  // Stop previous stream
  if (currentStream) {
    currentStream.getTracks().forEach(t => t.stop())
    currentStream = null
  }
  streamError.value = ''

  if (!deviceId) return

  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: {
        deviceId: { exact: deviceId },
        width: { ideal: 3840 },
        height: { ideal: 2160 },
      },
      audio: false,
    })
    currentStream = stream
    if (videoEl.value) {
      videoEl.value.srcObject = stream
    }
  } catch (err) {
    if (err.name === 'NotFoundError') {
      streamError.value = 'מכשיר הווידאו לא נמצא'
    } else if (err.name === 'NotAllowedError') {
      streamError.value = 'גישה למצלמה נדחתה'
    } else {
      streamError.value = err.message
    }
  }
}

watch(() => props.deviceId, (id) => startStream(id), { immediate: true })

onUnmounted(() => {
  if (currentStream) currentStream.getTracks().forEach(t => t.stop())
})
</script>

<style scoped>
.video-wrap {
  width: 100%;
  height: 100%;
  position: relative;
  background: #000;
}

.video-el {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.video-error {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #e74c3c;
  font-size: 1.1rem;
  background: rgba(0,0,0,0.7);
}
</style>
