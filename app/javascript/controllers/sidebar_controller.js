import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["sidebar", "toggleButton", "icon", "link"]

    connect() {
        const isCollapsed = localStorage.getItem('sidebarCollapsed') === 'true' || localStorage.getItem('sidebarCollapsed') === null
        this.toggleClass(isCollapsed)
        this.updateIcon(isCollapsed)
        this.linkTargets.forEach(link => {
            link.addEventListener('click', () => this.collapseSidebar())
        })
    }

    toggle() {
        const isCollapsed = !this.element.classList.contains('collapsed')
        this.toggleClass(isCollapsed)
        this.updateIcon(isCollapsed)
        localStorage.setItem('sidebarCollapsed', isCollapsed)
    }

    collapseSidebar() {
        this.toggleClass(true)
        this.updateIcon(true)
        localStorage.setItem('sidebarCollapsed', true)
    }

    toggleClass(isCollapsed) {
        this.element.classList.toggle('collapsed', isCollapsed)
    }

    updateIcon(isCollapsed) {
        this.iconTarget.classList.toggle('fa-bars', !isCollapsed)
        this.iconTarget.classList.toggle('fa-arrow-left', isCollapsed)
    }
}
