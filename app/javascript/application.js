import $ from 'jquery'
import select2 from 'select2'
import 'bootstrap'
import Rails from '@rails/ujs'

// select2's CommonJS build exports a factory that installs $.fn.select2 on the
// jQuery instance it is given.
select2(window, $)
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
// bookkeeping attributes are needed. Package names are user-entered, so every
// piece of text goes in through textContent, never innerHTML.
const paragraph = (text, className = 'mb-0') => {
  const p = document.createElement('p')
  p.className = className
  p.textContent = text
  return p
}

const renderShipment = (body, packages) => {
  if (!packages || packages.length === 0) {
    body.replaceChildren(paragraph('No combination of packages ships this order exactly.'))
    return
  }

  const list = document.createElement('ol')
  list.className = 'shipment-list mb-0'
  packages.forEach((name) => {
    const item = document.createElement('li')
    item.textContent = name
    list.appendChild(item)
  })

  const count = `${packages.length} package${packages.length === 1 ? '' : 's'}, no surplus:`
  body.replaceChildren(paragraph(count, 'mb-2'), list)
}

const wirePackagesModal = () => {
  const modal = document.getElementById('packagesModal')
  if (!modal) return

  modal.addEventListener('show.bs.modal', (event) => {
    const orderId = event.relatedTarget && event.relatedTarget.dataset.orderId
    const body = document.getElementById('packagesModalBody')

    document.getElementById('packagesModalOrderId').textContent = orderId
    document.getElementById('packagesModalOrderLink').setAttribute('href', `/orders/${encodeURIComponent(orderId)}`)
    body.replaceChildren(paragraph('Working it out…', 'text-muted mb-0'))

    fetch(`/select_optimal_packages?order_id=${encodeURIComponent(orderId)}`, { headers: { Accept: 'application/json' } })
      .then((response) => response.json().then((payload) => ({ ok: response.ok, payload })))
      .then(({ ok, payload }) => {
        if (ok) {
          renderShipment(body, payload.shipment_packages)
        } else {
          body.replaceChildren(paragraph(payload.error || 'No valid combination found'))
        }
      })
      .catch(() => {
        body.replaceChildren(paragraph('Could not reach the packaging service.'))
      })
  })
}

document.addEventListener('DOMContentLoaded', () => {
  enhanceProductSelects()
  wirePackagesModal()
})
