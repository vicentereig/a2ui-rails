import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

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
    document.getElementById('suggestions-section').classList.add('hidden')

    // Clear previous results
    document.getElementById('status-container').innerHTML = ''
    document.getElementById('suggestions-container').innerHTML = ''

    // Reset token display
    const tokenDisplay = document.getElementById('token-display')
    if (tokenDisplay) {
      tokenDisplay.classList.remove('hidden')
      tokenDisplay.querySelector('.token-model').textContent = '...'
      tokenDisplay.querySelector('.token-count').textContent = '0'
    }

    // Request briefing via ActionCable
    this.subscription.perform('request_briefing', { date: this.dateValue })
  }

  handleMessage(data) {
    switch (data.type) {
      case 'loading':
        document.getElementById('loading-state').classList.remove('hidden')
        document.getElementById('content-state').classList.add('hidden')
        break

      case 'status':
        document.getElementById('loading-state').classList.add('hidden')
        document.getElementById('content-state').classList.remove('hidden')
        document.getElementById('action-bar').classList.add('hidden')
        document.getElementById('status-container').innerHTML = data.html
        break

      case 'suggestion':
        document.getElementById('suggestions-section').classList.remove('hidden')
        document.getElementById('suggestions-container').insertAdjacentHTML('beforeend', data.html)
        break

      case 'complete':
        document.getElementById('loading-state').classList.add('hidden')
        document.getElementById('content-state').classList.remove('hidden')
        document.getElementById('action-bar').classList.remove('hidden')
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
        break

      case 'token_usage':
        this.updateTokenDisplay(data)
        break
    }
  }

  updateTokenDisplay(data) {
    const tokenDisplay = document.getElementById('token-display')
    if (!tokenDisplay) return

    tokenDisplay.classList.remove('hidden')

    // Format model name (remove provider prefix for display)
    const modelName = data.model ? data.model.split('/').pop() : '...'
    tokenDisplay.querySelector('.token-model').textContent = modelName

    // Format token count
    const total = data.total_tokens || 0
    tokenDisplay.querySelector('.token-count').textContent = this.formatTokenCount(total)

    // Update tooltip with detailed breakdown
    tokenDisplay.title = `Input: ${data.input_tokens || 0} | Output: ${data.output_tokens || 0}`
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
    // Update the current date value
    this.dateValue = dateStr

    // Update date values for next navigation
    const date = new Date(dateStr)
    const prevDate = new Date(date)
    prevDate.setDate(prevDate.getDate() - 1)
    const nextDate = new Date(date)
    nextDate.setDate(nextDate.getDate() + 1)

    this.prevDateValue = this.formatDateISO(prevDate)
    this.nextDateValue = this.formatDateISO(nextDate)

    // Update can go next (can't go past today)
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    this.canGoNextValue = date < today

    // Update next button state
    const nextBtn = document.getElementById('next-btn')
    if (nextBtn) {
      nextBtn.disabled = !this.canGoNextValue
    }

    // Update displayed date
    this.updateDisplayedDate(date)

    // Clear current content and request new briefing
    this.clearContent()
    this.subscription.perform('request_briefing', { date: dateStr })
  }

  updateDisplayedDate(date) {
    const dateEl = document.getElementById('briefing-date')
    if (dateEl) {
      const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }
      dateEl.textContent = date.toLocaleDateString('en-US', options)
    }
  }

  clearContent() {
    document.getElementById('status-container').innerHTML = ''
    document.getElementById('suggestions-container').innerHTML = ''
    document.getElementById('suggestions-section').classList.add('hidden')
    document.getElementById('error-state').classList.add('hidden')
    document.getElementById('warning-state').classList.add('hidden')

    // Reset token display
    const tokenDisplay = document.getElementById('token-display')
    if (tokenDisplay) {
      tokenDisplay.classList.add('hidden')
    }
  }

  formatDateISO(date) {
    return date.toISOString().split('T')[0]
  }
}
