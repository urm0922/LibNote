import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-nav"
export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    const isOpen = this.menuTarget.classList.toggle("is-open")

    event.currentTarget.setAttribute(
      "aria-expanded",
      isOpen.toString()
    )

    event.currentTarget.setAttribute(
      "aria-label",
      isOpen ? "メニューを閉じる" : "メニューを開く"
    )
  }
}
