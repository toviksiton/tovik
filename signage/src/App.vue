<template>
  <!-- Device picker shown until a device is confirmed -->
  <DevicePicker v-if="showPicker" @device-selected="onDeviceSelected" />

  <div v-else class="signage-grid">
    <!-- ── Video zone ───────────────────────────────────── -->
    <div class="video-zone">
      <VideoFeed :device-id="deviceId" />
    </div>

    <!-- ── Sidebar ─────────────────────────────────────── -->
    <div class="sidebar-zone">
      <ClockWidget />
      <AlertWidget
        :is-active="isActive"
        :active-alerts="activeAlerts"
        :alert-title="alertTitle"
        :last-updated="lastUpdated"
        :fetch-error="fetchError"
      />
    </div>

    <!-- ── Footer ticker ──────────────────────────────── -->
    <div class="ticker-zone">
      <div class="ticker-label">פיקוד העורף</div>
      <div class="ticker-status" :class="{ live: isActive }">
        {{ isActive ? '● התרעה פעילה' : '● שקט' }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, onUnmounted } from 'vue'
import DevicePicker from './components/DevicePicker.vue'
import VideoFeed from './components/VideoFeed.vue'
import ClockWidget from './components/ClockWidget.vue'
import AlertWidget from './components/AlertWidget.vue'
import { useAlerts } from './composables/useAlerts.js'

// ── Config ───────────────────────────────────────────────
const appConfig = ref({})
onMounted(async () => {
  try {
    const res = await fetch('./config.json')
    appConfig.value = await res.json()
  } catch {
    // use composable defaults
  }
})

// ── Alerts (single instance, shared to sidebar + ticker) ──
const { isActive, activeAlerts, alertTitle, lastUpdated, fetchError } = useAlerts(appConfig)

// ── Camera selection ──────────────────────────────────────
const storedDevice = localStorage.getItem('signage_device_id')
const deviceId = ref(storedDevice ?? '')
const showPicker = ref(!storedDevice)

function onDeviceSelected(id) {
  deviceId.value = id
  showPicker.value = false
}

// ── Keyboard shortcuts ────────────────────────────────────
function onKey(e) {
  // C — re-open camera picker
  if (e.key === 'c' || e.key === 'C') {
    showPicker.value = true
  }
  // F — toggle fullscreen
  if (e.key === 'f' || e.key === 'F') {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {})
    } else {
      document.exitFullscreen().catch(() => {})
    }
  }
}
onMounted(() => window.addEventListener('keydown', onKey))
onUnmounted(() => window.removeEventListener('keydown', onKey))
</script>

<style scoped>
.ticker-label {
  padding: 0 16px;
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--text-muted);
  white-space: nowrap;
  border-left: 1px solid var(--border);
  height: 100%;
  display: flex;
  align-items: center;
}

.ticker-status {
  padding: 0 14px;
  font-size: 0.8rem;
  color: var(--text-muted);
}

.ticker-status.live {
  color: var(--red);
  font-weight: 600;
  animation: alertPulse 0.8s infinite;
}
</style>
