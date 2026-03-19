<template>
  <div class="picker-overlay">
    <div class="picker-card">
      <h2>בחר מקור וידאו</h2>
      <p>בחר את כרטיס הלכידה או המצלמה שברצונך להציג</p>

      <div v-if="loading" style="color: var(--text-muted); text-align: center; padding: 20px;">
        מאתר מכשירים...
      </div>

      <template v-else-if="devices.length">
        <div class="device-list">
          <button
            v-for="device in devices"
            :key="device.deviceId"
            class="device-btn"
            :class="{ selected: selectedId === device.deviceId }"
            @click="selectedId = device.deviceId"
          >
            {{ device.label }}
          </button>
        </div>
        <button
          class="picker-confirm"
          :disabled="!selectedId"
          @click="confirm"
        >
          אישור
        </button>
      </template>

      <div v-else-if="permissionError" style="margin-top: 12px;">
        <p class="picker-error">{{ permissionError }}</p>
        <button class="picker-confirm" style="margin-top: 16px;" @click="retry">
          נסה שוב
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useVideoDevices } from '../composables/useVideoDevices.js'

const emit = defineEmits(['device-selected'])

const { devices, permissionError, loading, requestAndEnumerate } = useVideoDevices()
const selectedId = ref(localStorage.getItem('signage_device_id') ?? '')

onMounted(() => requestAndEnumerate())

function retry() {
  requestAndEnumerate()
}

function confirm() {
  if (!selectedId.value) return
  localStorage.setItem('signage_device_id', selectedId.value)
  emit('device-selected', selectedId.value)
}
</script>
