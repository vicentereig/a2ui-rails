import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

/**
 * A2UI Action Controller
 *
 * Handles user actions from buttons and other interactive components.
 * Resolves context paths from the data model and sends to server.
 *
 * Usage:
 *   <button data-controller="a2ui-action"
 *           data-a2ui-action-name-value="confirmBooking"
 *           data-a2ui-action-context-value='[{"key":"reservation","path":"/reservation"}]'
 *           data-a2ui-action-surface-value="booking"
 *           data-action="click->a2ui-action#dispatch">
 *     Confirm
 *   </button>
 */
export default class extends Controller {
  static values = {
    name: String,
    context: { type: Array, default: [] },
    surface: String,
    url: { type: String, default: "/a2ui/actions" },
    method: { type: String, default: "POST" },
    disabled: { type: Boolean, default: false }
  }

  static targets = ["loading"]

  connect() {
    // Store original content for loading state
    this.originalContent = this.element.innerHTML
  }

  /**
   * Dispatch action to server
   */
  async dispatch(event) {
    if (this.disabledValue) return

    event.preventDefault()

    // Show loading state
    this.#setLoading(true)

    try {
      const resolvedContext = this.#resolveContext()
      const payload = {
        action: this.nameValue,
        surface_id: this.surfaceValue,
        source_component_id: this.element.id,
        context: resolvedContext,
        timestamp: new Date().toISOString()
      }

      // Dispatch before-action event (cancelable)
      const beforeEvent = this.dispatch("before", {
        detail: payload,
        cancelable: true
      })

      if (beforeEvent.defaultPrevented) {
        this.#setLoading(false)
        return
      }

      const response = await fetch(this.urlValue, {
        method: this.methodValue,
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html, text/html",
          "X-CSRF-Token": this.#getCsrfToken()
        },
        body: JSON.stringify(payload)
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const contentType = response.headers.get("Content-Type") || ""

      if (contentType.includes("text/vnd.turbo-stream.html")) {
        // Turbo Stream response
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      } else if (contentType.includes("application/json")) {
        // JSON response (for custom handling)
        const json = await response.json()
        this.dispatch("success", { detail: { payload, response: json } })
      } else {
        // Plain HTML (full page redirect)
        const html = await response.text()
        document.body.innerHTML = html
      }

      this.dispatch("complete", { detail: payload })

    } catch (error) {
      console.error("A2UI Action failed:", error)
      this.dispatch("error", { detail: { error, action: this.nameValue } })
    } finally {
      this.#setLoading(false)
    }
  }

  // Private methods

  #resolveContext() {
    const dataController = window.a2uiSurfaces?.[this.surfaceValue]
    if (!dataController) {
      console.warn(`No data controller found for surface: ${this.surfaceValue}`)
      return {}
    }

    const resolved = {}

    this.contextValue.forEach(entry => {
      // Handle both object and key/path pair formats
      if (typeof entry === "object" && entry.key && entry.path) {
        resolved[entry.key] = dataController.get(entry.path)
      } else if (typeof entry === "object") {
        // Legacy format: {reservation: "/reservation"}
        Object.entries(entry).forEach(([key, path]) => {
          resolved[key] = dataController.get(path)
        })
      }
    })

    return resolved
  }

  #setLoading(loading) {
    this.disabledValue = loading

    if (loading) {
      this.element.setAttribute("disabled", "disabled")
      this.element.classList.add("a2ui-loading")

      if (this.hasLoadingTarget) {
        this.loadingTarget.classList.remove("hidden")
      }
    } else {
      this.element.removeAttribute("disabled")
      this.element.classList.remove("a2ui-loading")

      if (this.hasLoadingTarget) {
        this.loadingTarget.classList.add("hidden")
      }
    }
  }

  #getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
