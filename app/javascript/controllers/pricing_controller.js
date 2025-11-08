import { Controller } from "@hotwired/stimulus"

export default class extends Controller{
  static targets = ["periodButton", "card", "cardsContainer"]

  planDescriptions = {
    basic: "Perfect for individuals getting started",
    advanced: "Best for growing teams and businesses", 
    premium: "For large organizations and enterprises"
  }

  planFeatures = {
    basic: [
      "5 Projects",
      "10 GB Storage", 
      "Email Support",
      "Basic Analytics"
    ],
    advanced: [
      "Unlimited Projects",
      "100 GB Storage",
      "Priority Support 24/7", 
      "Advanced Analytics",
      "Team Collaboration",
      "API Access"
    ],
    premium: [
      "Everything in Advanced",
      "Unlimited Storage", 
      "Dedicated Account Manager",
      "Custom Integrations",
      "Advanced Security", 
      "SLA Guarantee"
    ]
  }

  connect() {
    // Initialize with first duration
    const firstDuration = this.periodButtonTargets[0]?.dataset.pricingDurationParam
    if (firstDuration) {
      this.changePeriod({ params: { duration: firstDuration } })
    }
  }

  changePeriod(event) {
    const duration = event.params.duration
    this.updateButtonStyles(duration)
    this.updateVisibleCards(duration)
  }

  updateButtonStyles(activeDuration) {
    // Remove active styles from all buttons
    this.periodButtonTargets.forEach(button => {
      button.classList.remove(
        'bg-gradient-to-r', 
        'from-indigo-600', 
        'to-purple-600', 
        'text-white', 
        'shadow-md'
      )
      button.classList.add(
        'text-gray-600', 
        'hover:text-gray-900'
      )
    })

    // Add active styles to current button
    const activeButton = this.periodButtonTargets.find(button => 
      button.dataset.pricingDurationParam === activeDuration.toString()
    )

    if (activeButton) {
      activeButton.classList.add(
        'bg-gradient-to-r', 
        'from-indigo-600', 
        'to-purple-600', 
        'text-white', 
        'shadow-md'
      )
      activeButton.classList.remove(
        'text-gray-600', 
        'hover:text-gray-900'
      )
    }
  }

  updateVisibleCards(duration) {
    // Hide all cards first
    this.cardTargets.forEach(card => {
      card.classList.add('hidden')
    })

    // Show cards for selected duration and maintain order: basic, advanced, premium
    const cardsForDuration = this.cardTargets.filter(card => 
      card.dataset.duration === duration.toString()
    )

    // Sort cards by plan type to maintain consistent order
    const sortedCards = cardsForDuration.sort((a, b) => {
      const planOrder = { basic: 0, advanced: 1, premium: 2 }
      return planOrder[a.dataset.planType] - planOrder[b.dataset.planType]
    })

    // Show cards in correct order
    sortedCards.forEach(card => {
      card.classList.remove('hidden')
    })

    // Ensure grid layout is maintained
    this.cardsContainerTarget.classList.add('grid', 'md:grid-cols-3', 'gap-8')
  }

  // Helper methods
  getPlanDescription(planType) {
    return this.planDescriptions[planType] || "Perfect for your needs"
  }

  getPlanFeatures(planType) {
    return this.planFeatures[planType] || ["Standard features", "Basic support"]
  }
}