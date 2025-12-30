import { Controller } from "@hotwired/stimulus"

/**
 * A2UI Binding Controller
 *
 * Two-way data binding between form inputs and the surface data model.
 * Automatically syncs input values with JSON Pointer paths.
 *
 * Usage:
 *   <input type="text"
 *          data-controller="a2ui-binding"
 *          data-a2ui-binding-path-value="/reservation/guests"
 *          data-a2ui-binding-surface-value="booking"
 *          data-action="input->a2ui-binding#update">
 */
export default class extends Controller {
  static values = {
    path: String,
    surface: String,
    debounce: { type: Number, default: 150 }
  }

  connect() {
    // Initial sync from data model
    this.#syncFromModel()

    // Listen for external model changes
    document.addEventListener("a2ui-data:changed", this.#handleModelChange)
  }

  disconnect() {
    document.removeEventListener("a2ui-data:changed", this.#handleModelChange)
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  /**
   * Update data model when input changes
   */
  update(event) {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    this.debounceTimer = setTimeout(() => {
      const value = this.#extractValue(event.target)
      const dataController = this.#getDataController()

      if (dataController) {
        dataController.set(this.pathValue, value)
      }

      // Dispatch binding event for other listeners
      this.dispatch("updated", {
        detail: {
          surface: this.surfaceValue,
          path: this.pathValue,
          value
        }
      })
    }, this.debounceValue)
  }

  /**
   * Force sync from model (useful after server updates)
   */
  sync() {
    this.#syncFromModel()
  }

  // Private methods

  #syncFromModel() {
    const dataController = this.#getDataController()
    if (!dataController) return

    const value = dataController.get(this.pathValue)
    if (value !== undefined) {
      this.#setValue(value)
    }
  }

  #handleModelChange = (event) => {
    const { surfaceId, path } = event.detail

    // Only update if this binding is affected
    if (surfaceId === this.surfaceValue && path === this.pathValue) {
      this.#syncFromModel()
    }
  }

  #getDataController() {
    return window.a2uiSurfaces?.[this.surfaceValue]
  }

  #extractValue(element) {
    const tagName = element.tagName.toLowerCase()
    const type = element.type?.toLowerCase()

    if (tagName === "input") {
      switch (type) {
        case "checkbox":
          return element.checked
        case "number":
        case "range":
          return parseFloat(element.value)
        case "date":
        case "datetime-local":
          return element.value // ISO string
        default:
          return element.value
      }
    } else if (tagName === "select") {
      return element.multiple
        ? Array.from(element.selectedOptions).map(o => o.value)
        : element.value
    } else if (tagName === "textarea") {
      return element.value
    }

    return element.value
  }

  #setValue(value) {
    const element = this.element
    const tagName = element.tagName.toLowerCase()
    const type = element.type?.toLowerCase()

    if (tagName === "input") {
      if (type === "checkbox") {
        element.checked = Boolean(value)
      } else {
        element.value = value ?? ""
      }
    } else if (tagName === "select") {
      if (element.multiple && Array.isArray(value)) {
        Array.from(element.options).forEach(option => {
          option.selected = value.includes(option.value)
        })
      } else {
        element.value = value ?? ""
      }
    } else if (tagName === "textarea") {
      element.value = value ?? ""
    }
  }
}
