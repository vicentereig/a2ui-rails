import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = {
    userId: String,
    date: String
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
    }
  }
}
