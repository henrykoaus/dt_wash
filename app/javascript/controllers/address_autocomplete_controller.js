import { Controller } from "@hotwired/stimulus"
import MapboxGeocoder from "@mapbox/mapbox-gl-geocoder"

// Connects to data-controller="address-autocomplete"
export default class extends Controller {
  static values = { apiKey: String }
  static targets = ["address"]

  connect() {
    this.geocoder = new MapboxGeocoder({
      accessToken: this.apiKeyValue,
      types: "country,region,place,postcode,locality,neighborhood,address",
      placeholder: "🔍 Search for an address...",
      marker: false,
      flyTo: false
    })

    this.geocoder.addTo(this.element)

    this.geocoder._inputEl.classList.add(
      "form-control",
      "pokemon-search-bar",
      "pokemon-search-focus"
    )

    this.geocoder.on("result", event => this.#setInputValue(event))
    this.geocoder.on("clear", () => this.#clearInputValue())

    this.geocoder._inputEl.addEventListener("focus", () => {
      this.geocoder._inputEl.classList.add("pokemon-search-glow")
    })
    this.geocoder._inputEl.addEventListener("blur", () => {
      this.geocoder._inputEl.classList.remove("pokemon-search-glow")
    })
  }

  #setInputValue(event) {
    this.addressTarget.value = event.result["place_name"]
  }

  #clearInputValue() {
    this.addressTarget.value = ""
  }

  disconnect() {
    this.geocoder.onRemove()
  }
}
