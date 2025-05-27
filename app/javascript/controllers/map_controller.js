import { Controller } from "@hotwired/stimulus"
import mapboxgl from 'mapbox-gl'
import MapboxGeocoder from "@mapbox/mapbox-gl-geocoder"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    apiKey: String,
    marker: Object
  };

  connect() {
    console.log("connected !! i mean map");

    mapboxgl.accessToken = this.apiKeyValue;

    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/pdunleav/cjofefl7u3j3e2sp0ylex3cyb",
      center: [this.markerValue.lng, this.markerValue.lat],
      zoom: 12
    });

    this.#addMarkerToMap();
  }

  #addMarkerToMap() {
    const popup = new mapboxgl.Popup().setHTML(this.markerValue.info_window_html);

    const customMarker = document.createElement("div");
    customMarker.innerHTML = this.markerValue.marker_html;

    new mapboxgl.Marker(customMarker)
      .setLngLat([this.markerValue.lng, this.markerValue.lat])
      .setPopup(popup)
      .addTo(this.map);
  }
}
