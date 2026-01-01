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
    document.getElementById('generate-section').classList.add('hidden')
    document.getElementById('error-state').classList.add('hidden')
    document.getElementById('complete-state').classList.add('hidden')

    // Clear previous results
    document.getElementById('insights-container').innerHTML = ''
    document.getElementById('suggestions-container').innerHTML = ''
    document.getElementById('greeting').classList.add('hidden')

    // Request briefing via ActionCable
    this.subscription.perform('request_briefing', { date: this.dateValue })
  }

  handleMessage(data) {
    switch (data.type) {
      case 'loading':
        document.getElementById('loading-state').classList.remove('hidden')
        break

      case 'insight':
        document.getElementById('loading-state').classList.add('hidden')
        document.getElementById('insights-container').insertAdjacentHTML('beforeend', data.html)
        break

      case 'suggestion':
        document.getElementById('suggestions-container').insertAdjacentHTML('beforeend', data.html)
        break

      case 'complete':
        document.getElementById('loading-state').classList.add('hidden')
        document.getElementById('complete-state').classList.remove('hidden')
        document.getElementById('generate-section').classList.remove('hidden')
        break

      case 'error':
        document.getElementById('loading-state').classList.add('hidden')
        document.getElementById('error-state').classList.remove('hidden')
        document.getElementById('error-message').textContent = data.message
        document.getElementById('generate-section').classList.remove('hidden')
        break
    }
  }
}
