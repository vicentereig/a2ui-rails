import { Controller } from "@hotwired/stimulus"

/**
 * A2UI Data Controller
 *
 * Manages the surface data model using JSON Pointer paths.
 * Acts as the central store for component data binding.
 *
 * Usage:
 *   <div data-controller="a2ui-data"
 *        data-a2ui-data-surface-value="booking"
 *        data-a2ui-data-model-value='{"reservation":{"guests":"2"}}'>
 *   </div>
 */
export default class extends Controller {
  static values = {
    surface: String,
    model: Object
  }

  connect() {
    // Register this controller globally for cross-component access
    window.a2uiSurfaces = window.a2uiSurfaces || {}
    window.a2uiSurfaces[this.surfaceValue] = this

    // Dispatch ready event
    this.dispatch("ready", { detail: { surfaceId: this.surfaceValue } })
  }

  disconnect() {
    if (window.a2uiSurfaces) {
      delete window.a2uiSurfaces[this.surfaceValue]
    }
  }

  /**
   * Get value at JSON Pointer path
   * @param {string} path - JSON Pointer path (e.g., "/reservation/guests")
   * @returns {any} Value at path or undefined
   */
  get(path) {
    return this.#resolvePath(path, this.modelValue)
  }

  /**
   * Set value at JSON Pointer path
   * @param {string} path - JSON Pointer path
   * @param {any} value - Value to set
   */
  set(path, value) {
    const newModel = this.#setPath(path, value, { ...this.modelValue })
    this.modelValue = newModel

    // Dispatch change event for reactive updates
    this.dispatch("changed", {
      detail: {
        surfaceId: this.surfaceValue,
        path,
        value,
        model: newModel
      }
    })
  }

  /**
   * Apply multiple updates from server
   * @param {Array} updates - Array of {path, contents} objects
   */
  applyUpdates(updates) {
    let newModel = { ...this.modelValue }

    updates.forEach(update => {
      const pathValue = this.#contentsToObject(update.contents)
      newModel = this.#setPath(update.path, pathValue, newModel)
    })

    this.modelValue = newModel
    this.dispatch("updated", { detail: { surfaceId: this.surfaceValue, model: newModel } })
  }

  /**
   * Get the entire model as JSON
   * @returns {string} JSON string
   */
  toJSON() {
    return JSON.stringify(this.modelValue)
  }

  // Private methods

  #resolvePath(path, obj) {
    if (!path || path === "/") return obj

    const parts = path.split("/").filter(p => p !== "")
    let current = obj

    for (const part of parts) {
      if (current === undefined || current === null) return undefined
      current = current[part]
    }

    return current
  }

  #setPath(path, value, obj) {
    if (!path || path === "/") return value

    const parts = path.split("/").filter(p => p !== "")
    const result = { ...obj }
    let current = result

    for (let i = 0; i < parts.length - 1; i++) {
      const part = parts[i]
      if (!(part in current) || typeof current[part] !== "object") {
        current[part] = {}
      } else {
        current[part] = { ...current[part] }
      }
      current = current[part]
    }

    current[parts[parts.length - 1]] = value
    return result
  }

  #contentsToObject(contents) {
    const result = {}

    contents.forEach(entry => {
      if (entry.value_string !== undefined && entry.value_string !== null) {
        result[entry.key] = entry.value_string
      } else if (entry.value_number !== undefined && entry.value_number !== null) {
        result[entry.key] = entry.value_number
      } else if (entry.value_boolean !== undefined && entry.value_boolean !== null) {
        result[entry.key] = entry.value_boolean
      } else if (entry.value_array && entry.value_array.length > 0) {
        result[entry.key] = this.#contentsToObject(entry.value_array)
      }
    })

    return result
  }
}
