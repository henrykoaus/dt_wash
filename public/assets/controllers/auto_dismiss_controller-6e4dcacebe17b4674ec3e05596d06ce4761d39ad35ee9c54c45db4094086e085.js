// app/javascript/controllers/auto_dismiss_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        setTimeout(() => {
            this.element.style.transition = "opacity 1s";
            this.element.style.opacity = "0";
            setTimeout(() => this.element.remove(), 1000);
        }, 500);
    }
};
