// app/javascript/controllers/cloth_upload_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
    static targets = ["fileInput", "dropZone", "formsContainer", "formTemplate", "totalPrice", "totalInput", "alertContainer", "alertText"]

    connect() {
        const pricesElement = document.getElementById('clothing-prices')
        this.clothingPrices = {}
    }

    openFileDialog() {
        this.fileInputTarget.click()
    }

    handleFiles(event) {
        this.processFiles(event.target.files)
        event.target.value = null
    }

    highlightDropZone(event) {
        event.preventDefault()
        this.dropZoneTarget.classList.add('bg-primary', 'text-white')
    }

    unhighlightDropZone(event) {
        event.preventDefault()
        this.dropZoneTarget.classList.remove('bg-primary', 'text-white')
    }

    handleDrop(event) {
        event.preventDefault()
        this.unhighlightDropZone(event)
        this.processFiles(event.dataTransfer.files)
    }

    // Main processing flow
    async processFiles(files) {
        const loadingOverlay = document.getElementById('loading-overlay');
        const loadingMessage = document.getElementById('loading-message');
        loadingMessage.textContent = "recognizing cloth"; // Set the loading message
        loadingOverlay.classList.remove('d-none'); // Show loading overlay

        for (const file of Array.from(files)) {
            try {
                if (!this.validateFile(file)) continue;

                const formData = new FormData();
                formData.append('image', file);

                const response = await fetch('/analyze_image', {
                    method: 'POST',
                    body: formData,
                    headers: {
                        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                    }
                });

                if (!response.ok) {
                    throw new Error(data.error || 'Analysis failed');
                }

                const { cloth_type, color, cloth_types, colors, cloth_prices } = await response.json();
                console.log(`Detected color: ${color}, cloth types: ${cloth_type}`);
                this.clothingPrices = cloth_prices;
                this.createFormElement(file, cloth_type, color, cloth_types, colors);
            } catch (error) {
                this.handleProcessingError(file, error);
            }
        }

        loadingOverlay.classList.add('d-none'); // Hide loading overlay
    }

    createHiddenInput(clothingId) {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'order[clothing_ids][]'
        input.value = clothingId
        this.formsContainerTarget.appendChild(input)
    }

    // File validation
    validateFile(file) {
        if (!file.type.startsWith('image/')) {
            alert(`Skipped ${file.name}: Not an image file`)
            return false
        }

        if (file.size > 5 * 1024 * 1024) {
            alert(`Skipped ${file.name}: File too large (max 5MB)`)
            return false
        }

        return true
    }


// In your Stimulus controller
    createFormElement(file, clothType, color, clothTypes, colors) {
        const uniqueId = Date.now() + Math.floor(Math.random() * 1000);
        const clone = this.formTemplateTarget.cloneNode(true);

        // Prepare clone
        clone.classList.remove('d-none');
        clone.removeAttribute('data-cloth-upload-target');

        // Get elements
        const previewContainer = clone.querySelector('.image-preview-container');
        const img = document.createElement('img');
        img.src = URL.createObjectURL(file);
        img.className = 'img-thumbnail';
        img.style.maxWidth = '100px';
        img.style.maxHeight = '100px';
        previewContainer.appendChild(img);
        const typeSelect = clone.querySelector('.cloth-type-select');
        const colorSelect = clone.querySelector('.color-select');
        const priceInput = clone.querySelector('.price-input')
        const fileInput = clone.querySelector('input[type="file"]');

        // Add remove button
        const removeButton = document.createElement('button');
        removeButton.type = 'button';
        removeButton.className = 'remove-btn';
        removeButton.textContent = '🗑️';
        removeButton.addEventListener('click', () => {
            URL.revokeObjectURL(img.src); // Free memory
            clone.remove();
            this.updateTotalPrice();
        });

        // Append remove button to the same row
        const actionCol = document.createElement('div');
        actionCol.className = 'col-lg-1 col-md-2 col-sm-2 text-center';
        actionCol.appendChild(removeButton);
        clone.querySelector('.row').appendChild(actionCol);

        // create header row if it doesn't exist
        // if (!this.formsContainerTarget.querySelector('.column-headers')) {
        //     const headerRow = document.createElement('div');
        //     headerRow.className = 'row column-headers mb-2';
        //     headerRow.innerHTML = `
        //       <div class="col-md-3"><strong>Image Preview</strong></div>
        //       <div class="col-md-2"><strong>Cloth Type</strong></div>
        //       <div class="col-md-2"><strong>Color</strong></div>
        //       <div class="col-md-2"><strong>Price ($)</strong></div>
        //       <div class="col-md-2"><strong>Action</strong></div>
        //     `;
        //     this.formsContainerTarget.prepend(headerRow);
        // }

        // Clear existing options and keep only the default
        if(clothType === "Unknown") {
            this.triggerFlash("Unknown cloth type detected, please select manually");
            typeSelect.innerHTML = '<option value="">Select Clothing Type</option>';
        } else {
            typeSelect.innerHTML = `<option value="${clothType}">${clothType}</option>`;
        }
        colorSelect.innerHTML = `<option value="${color}">${color}</option>`;
        // Populate cloth types from AJAX response
        clothTypes.forEach(type => {
            const option = document.createElement('option');
            option.value = type;
            option.textContent = type;
            typeSelect.appendChild(option);
        });

        // Populate colors from AJAX response
        colors.forEach(color => {
            const option = document.createElement('option');
            option.value = color;
            option.textContent = color;
            colorSelect.appendChild(option);
        });

        // Initialize price
        const initialPrice = this.clothingPrices[clothType] || 0
        priceInput.value = initialPrice
        priceInput.name = `order[clothings_attributes][${uniqueId}][price]`

        // Set up event listener for type changes
        typeSelect.addEventListener('change', () => {
            const selectedType = typeSelect.value
            priceInput.value = this.clothingPrices[selectedType] || 0
            this.updateTotalPrice()
        })



        // Configure file input
        const dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        fileInput.files = dataTransfer.files;
        fileInput.name = `order[clothings_attributes][${uniqueId}][photo]`;

        // Update select names
        typeSelect.name = `order[clothings_attributes][${uniqueId}][cloth_type]`;
        colorSelect.name = `order[clothings_attributes][${uniqueId}][color]`;

        this.formsContainerTarget.appendChild(clone);
        this.updateTotalPrice()
    }

    updateTotalPrice() {
        const priceInputs = Array.from(this.formsContainerTarget.querySelectorAll('.price-input'))
        const total = priceInputs.reduce((sum, input) => sum + (parseFloat(input.value) || 0), 0)
        this.totalPriceTarget.textContent = total.toFixed(2)
        this.totalInputTarget.value = total.toFixed(2)
    }


    // Error handling
    handleProcessingError(file, error) {
        console.error(`Error processing ${file.name}:`, error)
        alert(`Failed to process ${file.name}: ${error.message}`)
    }

    triggerFlash(message) {
        const flashContainer = document.createElement('div');
        flashContainer.className = 'pokemon-alert alert-dismissible fade show';
        flashContainer.role = 'alert';
        flashContainer.setAttribute('data-controller', 'auto-dismiss');
        flashContainer.innerHTML = `
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        ${message}
    `;
        document.body.appendChild(flashContainer);
    }
    checkBeforeSubmit(event) {
        const loadingOverlay = document.getElementById('loading-overlay');
        const loadingMessage = document.getElementById('loading-message');
        loadingMessage.textContent = "creating order"; // Set the loading message
        loadingOverlay.classList.remove('d-none'); // Show loading overlay

        if (!this.checkClothTypes() || !this.checkAddress() || !this.checkNotes()) {
            event.preventDefault();
            loadingOverlay.classList.add('d-none'); // Hide loading overlay if checks fail
        }
    }

    checkClothTypes() {
        const typeSelects = Array.from(this.formsContainerTarget.querySelectorAll('.cloth-type-select'));
        if (typeSelects.length === 0) {
            this.triggerFlash("Please add cloth.");
            return false;
        }
        for (const select of typeSelects) {
            console.log(`Checking select value: ${select.value}`);
            if (select.value === "" || select.value === "Select Clothing Type") {
                this.triggerFlash("Please select a valid clothing type for all items.");
                return false;
            }
        }
        return true;
    }

    checkAddress() {
        const addressInput = this.element.querySelector('[data-address-autocomplete-target="address"]');
        if (!addressInput || addressInput.value.trim() === "") {
            this.triggerFlash("Please enter a valid address.");
            return false;
        }
        return true;
    }

    checkNotes() {
        const notesInput = this.element.querySelector('[data-notes-autocomplete-target="notes"]');
        if (!notesInput || notesInput.value.trim() === "") {
            this.triggerFlash("Please enter some notes.");
            return false;
        }
        return true;
    }

    // Function to remove clothing
    removeClothing(event) {
        const clothingCard = event.target.closest('.cloth-card');
        if (clothingCard) {
            const img = clothingCard.querySelector('img');
            if (img) {
                URL.revokeObjectURL(img.src); // Free memory
            }
            clothingCard.remove();
            this.updateTotalPrice();
        }
    }
}
