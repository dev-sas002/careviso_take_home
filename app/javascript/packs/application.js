import $ from 'jquery'
window.jQuery = $
window.$ = $

import 'select2/dist/js/select2.min.js'
import 'select2/dist/css/select2.min.css'
import '@popperjs/core'
import 'bootstrap/dist/js/bootstrap'
import 'bootstrap/dist/css/bootstrap.css'
import Rails from '@rails/ujs'

Rails.start()

// Multi-selects for "which products" on the order and package forms.
const enhanceProductSelects = () => {
  const select = $('#products-select')
  if (select.length === 0) return

  select.select2({
    placeholder: 'Select products…',
    allowClear: true,
    width: '100%'
  })
}

// The orders list asks the JSON endpoint for the optimal shipment and renders it
// in a modal. Bootstrap 5 hands us the button that opened the modal, so no
// bookkeeping attributes are needed.
const renderShipment = (body, packages) => {
  if (!packages || packages.length === 0) {
    body.innerHTML =
      '<p class="mb-0">No combination of packages ships this order exactly.</p>'
    return
  }

  const items = packages.map((name) => `<li>${name}</li>`).join('')
  body.innerHTML = `
    <p class="mb-2">${packages.length} package${packages.length === 1 ? '' : 's'}, no surplus:</p>
    <ol class="shipment-list mb-0">${items}</ol>
  `
}

const wirePackagesModal = () => {
  const modal = document.getElementById('packagesModal')
  if (!modal) return

  modal.addEventListener('show.bs.modal', (event) => {
    const orderId = event.relatedTarget && event.relatedTarget.dataset.orderId
    const body = document.getElementById('packagesModalBody')

    document.getElementById('packagesModalOrderId').textContent = orderId
    document.getElementById('packagesModalOrderLink').setAttribute('href', `/orders/${orderId}`)
    body.innerHTML = '<p class="text-muted mb-0">Working it out…</p>'

    fetch(`/select_optimal_packages?order_id=${orderId}`)
      .then((response) => response.json().then((payload) => ({ ok: response.ok, payload })))
      .then(({ ok, payload }) => {
        if (ok) {
          renderShipment(body, payload.shipment_packages)
        } else {
          body.innerHTML = `<p class="mb-0">${payload.error || 'No valid combination found'}</p>`
        }
      })
      .catch(() => {
        body.innerHTML = '<p class="mb-0">Could not reach the packaging service.</p>'
      })
  })
}

document.addEventListener('DOMContentLoaded', () => {
  enhanceProductSelects()
  wirePackagesModal()
})
