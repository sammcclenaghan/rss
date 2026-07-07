// Shared timing utilities for Stimulus controllers.

// Returns a debounced wrapper that runs `fn` once `delay` ms after the last
// call. The wrapper exposes cancel() to drop a pending run.
export function debounce(fn, delay) {
  let timer = null

  const debounced = (...args) => {
    clearTimeout(timer)
    timer = setTimeout(() => fn(...args), delay)
  }

  debounced.cancel = () => clearTimeout(timer)

  return debounced
}
