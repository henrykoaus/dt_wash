import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["tooltip"];

    connect() {
        this.tooltip = document.createElement('div');
        this.tooltip.className = 'tooltip';
        document.body.appendChild(this.tooltip);
    }

    mouseenter(event) {
        const { tooltipClothType, tooltipPrice, tooltipColor } = this.element.dataset;
        this.tooltip.innerHTML = `
            <div class="tooltip-content">
                <strong>Type:</strong> ${tooltipClothType}<br>
                <strong>Price:</strong> $${tooltipPrice}<br>
                <strong>Color:</strong> ${tooltipColor}
            </div>
        `;
        this.tooltip.style.display = 'block';
        this.mousemove(event); // Set initial position
    }

    mousemove(event) {
        const offset = 15;
        this.tooltip.style.left = `${event.pageX + offset}px`;
        this.tooltip.style.top = `${event.pageY + offset}px`;
    }

    mouseleave() {
        this.tooltip.style.display = 'none';
    }

    // Cleanup when controller disconnects
    disconnect() {
        this.tooltip.remove();
    }
}
