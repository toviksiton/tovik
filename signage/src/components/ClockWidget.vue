<template>
  <div class="panel clock-panel">
    <div class="clock-time">{{ timeStr }}</div>
    <div class="clock-date">{{ dateStr }}</div>
  </div>
</template>

<script setup>
import { useClock } from '../composables/useClock.js'
const { timeStr, dateStr } = useClock()
</script>

<style scoped>
.clock-panel {
  text-align: center;
  flex-shrink: 0;
}

.clock-time {
  font-size: 2.6rem;
  font-weight: 700;
  letter-spacing: 0.06em;
  color: var(--text-main);
  font-variant-numeric: tabular-nums;
  font-family: 'SF Mono', 'Fira Code', 'Courier New', monospace;
  line-height: 1;
  margin-bottom: 6px;
}

.clock-date {
  font-size: 0.78rem;
  color: var(--text-muted);
  line-height: 1.4;
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
