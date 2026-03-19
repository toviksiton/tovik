<template>
  <div class="alert-panel" :class="{ active: isActive }">
    <!-- No active alerts -->
    <div v-if="!isActive" class="quiet-state">
      <span class="status-dot quiet-dot"></span>
      <span class="quiet-label">שקט</span>
      <span v-if="lastUpdated" class="last-update">עודכן {{ updateTime }}</span>
    </div>

    <!-- Active alert -->
    <div v-else class="alert-state">
      <div class="alert-header">
        <span class="status-dot alert-dot"></span>
        <span class="alert-title">{{ alertTitle || 'התרעה' }}</span>
      </div>
      <ul class="location-list">
        <li v-for="loc in activeAlerts" :key="loc">{{ loc }}</li>
      </ul>
      <div v-if="lastUpdated" class="alert-time">{{ updateTime }}</div>
    </div>

    <!-- Non-blocking fetch error -->
    <div v-if="fetchError" class="fetch-error">⚠ {{ fetchError }}</div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { formatTime } from '../utils/formatters.js'

const props = defineProps({
  isActive:     { type: Boolean, default: false },
  activeAlerts: { type: Array,   default: () => [] },
  alertTitle:   { type: String,  default: '' },
  lastUpdated:  { type: Date,    default: null },
  fetchError:   { type: String,  default: '' },
})

const updateTime = computed(() =>
  props.lastUpdated ? formatTime(props.lastUpdated) : ''
)
</script>

<style scoped>
.alert-panel {
  padding: 14px 12px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--bg-panel);
  flex: 1;
  display: flex;
  flex-direction: column;
  transition: border-color 0.3s;
  min-height: 0;
  overflow: hidden;
}

.alert-panel.active {
  border-color: var(--red);
  background: var(--red-dark);
  animation: alertPulse 0.8s infinite;
}

/* ── Quiet state ──────────────────────────────────────────── */
.quiet-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 12px 0;
}

.status-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  display: inline-block;
}

.quiet-dot {
  background: var(--green);
  box-shadow: 0 0 8px var(--green);
}

.alert-dot {
  background: #fff;
  box-shadow: 0 0 8px rgba(255,255,255,0.8);
}

.quiet-label {
  font-size: 1.4rem;
  font-weight: 700;
  color: var(--green);
}

.last-update {
  font-size: 0.72rem;
  color: var(--text-muted);
}

/* ── Active alert ─────────────────────────────────────────── */
.alert-state {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.alert-header {
  display: flex;
  align-items: center;
  gap: 8px;
}

.alert-title {
  font-size: 1.1rem;
  font-weight: 700;
  color: #fff;
  line-height: 1.2;
}

.location-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 4px;
  max-height: 240px;
  overflow-y: auto;
}

.location-list li {
  font-size: 0.88rem;
  color: #fff;
  padding: 3px 0;
  border-bottom: 1px solid rgba(255,255,255,0.15);
}

.alert-time {
  font-size: 0.72rem;
  color: rgba(255,255,255,0.6);
  margin-top: auto;
}

/* ── Error ────────────────────────────────────────────────── */
.fetch-error {
  font-size: 0.72rem;
  color: var(--red);
  margin-top: 8px;
  word-break: break-all;
}
</style>
