import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"
import { Turbo } from "@hotwired/turbo-rails"

// Editorial Briefing Controller
// Handles the What/So What/Now What journalistic-style briefings
export default class extends Controller {
  static values = {
    userId: String,
    date: String,
    prevDate: String,
    nextDate: String,
    canGoNext: Boolean
  }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "BriefingChannel", user_id: this.userIdValue },
      {
        received: (data) => this.handleMessage(data)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  generate() {
    // Show loading state
    document.getElementById('loading-state').classList.remove('hidden')
    document.getElementById('content-state').classList.add('hidden')
    document.getElementById('error-state').classList.add('hidden')
    document.getElementById('warning-state').classList.add('hidden')

    // Show generating indicator
    this.setGenerating(true)

    // Clear previous content
    document.getElementById('editorial-content').innerHTML = ''

    // Request editorial briefing via ActionCable
    this.subscription.perform('request_editorial_briefing', {
      date: this.dateValue,
      force: true
    })
  }

  handleMessage(data) {
    switch (data.type) {
      case 'loading':
        document.getElementById('loading-state').classList.remove('hidden')
        document.getElementById('content-state').classList.add('hidden')
        this.setGenerating(true)
        break

      case 'editorial':
        document.getElementById('loading-state').classList.add('hidden')
        document.getElementById('content-state').classList.remove('hidden')
        document.getElementById('editorial-content').innerHTML = data.html
        this.setGenerating(false)
        break

      case 'complete':
        document.getElementById('loading-state').classList.add('hidden')
        document.getElementById('content-state').classList.remove('hidden')
        document.getElementById('action-bar').classList.remove('hidden')
        this.setGenerating(false)
        break

      case 'warning':
        document.getElementById('warning-state').classList.remove('hidden')
        document.getElementById('warning-message').textContent = data.message
        break

      case 'error':
        document.getElementById('loading-state').classList.add('hidden')
        document.getElementById('content-state').classList.remove('hidden')
        document.getElementById('error-state').classList.remove('hidden')
        document.getElementById('error-message').textContent = data.message
        document.getElementById('action-bar').classList.remove('hidden')
        this.setGenerating(false)
        break

      case 'token_usage':
        this.updateTokenDisplay(data)
        break
    }
  }

  setGenerating(isGenerating) {
    const dot = document.getElementById('activity-dot')
    if (!dot) return

    if (isGenerating) {
      dot.classList.add('editorial-meta__dot--generating')
    } else {
      dot.classList.remove('editorial-meta__dot--generating')
    }
  }

  updateTokenDisplay(data) {
    // Format model name (remove provider prefix for display)
    const modelName = data.model ? data.model.split('/').pop() : '...'
    const modelEl = document.getElementById('model-name')
    if (modelEl) modelEl.textContent = modelName

    // Update token counts
    const inputEl = document.getElementById('input-tokens')
    const outputEl = document.getElementById('output-tokens')
    if (inputEl) inputEl.textContent = this.formatTokenCount(data.input_tokens || 0)
    if (outputEl) outputEl.textContent = this.formatTokenCount(data.output_tokens || 0)
  }

  formatTokenCount(count) {
    if (count >= 1000) {
      return (count / 1000).toFixed(1) + 'k'
    }
    return count.toString()
  }

  prevDay() {
    this.navigateToDate(this.prevDateValue)
  }

  nextDay() {
    if (!this.canGoNextValue) return
    this.navigateToDate(this.nextDateValue)
  }

  navigateToDate(dateStr) {
    const url = this.buildDateUrl(dateStr)
    Turbo.visit(url)
  }

  buildDateUrl(dateStr) {
    // dateStr is in YYYY-MM-DD format
    const [year, month, day] = dateStr.split('-')
    return `/${year}/${month}/${day}/editorial`
  }
}
