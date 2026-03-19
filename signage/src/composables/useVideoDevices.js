import { ref } from 'vue'

export function useVideoDevices() {
  const devices = ref([])
  const permissionError = ref('')
  const loading = ref(false)

  async function requestAndEnumerate() {
    loading.value = true
    permissionError.value = ''
    try {
      // Phase 1: trigger permission prompt with a minimal stream, then release
      const tempStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      tempStream.getTracks().forEach(t => t.stop())

      // Phase 2: enumerate — labels are now populated
      const all = await navigator.mediaDevices.enumerateDevices()
      devices.value = all
        .filter(d => d.kind === 'videoinput')
        .map(d => ({ deviceId: d.deviceId, label: d.label || `Camera ${d.deviceId.slice(0, 6)}` }))
    } catch (err) {
      if (err.name === 'NotAllowedError') {
        permissionError.value = 'יש לאשר גישה למצלמה בדפדפן'
      } else if (err.name === 'NotFoundError') {
        permissionError.value = 'לא נמצאו מכשירי וידאו'
      } else {
        permissionError.value = err.message
      }
    } finally {
      loading.value = false
    }
  }

  return { devices, permissionError, loading, requestAndEnumerate }
}
