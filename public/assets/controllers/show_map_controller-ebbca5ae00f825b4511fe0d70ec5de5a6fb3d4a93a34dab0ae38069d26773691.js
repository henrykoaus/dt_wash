import { Controller } from "@hotwired/stimulus"
import mapboxgl from 'mapbox-gl'

export default class extends Controller {
static values = {
        apiKey: String,
        markers: Array,
        latitude: Number,
        longitude: Number
    };

    connect() {
      // console.log(this.latitudeValue, this.longitudeValue);  // Log latitude and longitude to debug

      mapboxgl.accessToken = this.apiKeyValue;

      this.map = new mapboxgl.Map({
          container: this.element,
          style: 'mapbox://styles/mapbox/streets-v12',
          center: [this.longitudeValue, this.latitudeValue], // Use the coordinates from the controller
          zoom: 10
      });

      this.#addMarkersToMap();  // Adds markers to the map
      this.#fitMapToMarkers();  // Adjusts map view to fit all markers

      // Add zoom buttons to the map:
      this.map.addControl(new mapboxgl.NavigationControl(), 'top-right');
    }

    #addMarkersToMap() {
        this.markersValue.forEach((marker) => {
            const popup = new mapboxgl.Popup().setHTML(marker.info_window_html);

            const customMarker = document.createElement("div");
            customMarker.innerHTML = marker.marker_html;

            new mapboxgl.Marker(customMarker)
                .setLngLat([marker.lng, marker.lat])
                .setPopup(popup)
                .addTo(this.map);
        });
    }

    #fitMapToMarkers() {
        const bounds = new mapboxgl.LngLatBounds();
        this.markersValue.forEach(marker =>
            bounds.extend([marker.lng, marker.lat])
        );
        this.map.fitBounds(bounds, { padding: 50, maxZoom: 15 });
    }
};
