import $ from 'jquery';
window.jQuery = $;
window.$ = $;
import 'select2/dist/js/select2.min.js'
import 'select2/dist/css/select2.min.css'
import '@popperjs/core'
import 'bootstrap/dist/js/bootstrap'
import 'bootstrap/dist/css/bootstrap.css'
import Rails from "@rails/ujs"
Rails.start()

$(document).ready(function() {
  $('#products-select').select2({
    placeholder: "Select products...",
    allowClear: true
  });

  $('#packagesModal').on('show.bs.modal', function(event) {
    const modal = $(this);
    const orderId = modal.attr('data-active-order-id');
    $('#orderId').text(orderId)

    fetch(`/select_optimal_packages?order_id=${orderId}`)
      .then(response => {
        if (!response.ok) {
          return response.json().then(err => { throw err; });
        }
        return response.json();
      })
      .then(data => {
        if (data.shipment_packages) {
          $('#packagesContent').html(data.shipment_packages.join(', '))
        } 
        else {
          $('#packagesContent').html('<p>No valid combination found</p>')
        }
      })
      .catch(error => {
        if (error && error.error === 'No valid packages found') {
          $('#packagesContent').html('<p>No valid combination found</p>')
        } 
        else {
          $('#packagesContent').html('<p>Error fetching packages</p>')
        }
      })      
  })

  $('#packagesModal').on('hidden.bs.modal', function() {
    $(this).removeAttr('data-active-order-id')
  })

  $('a[data-toggle="modal"]').on('click', function(e) {
    e.preventDefault()
    const orderId = $(this).data('orderId')

    $($(this).data('target')).attr('data-active-order-id', orderId).modal('show')
  })

  $('.close, .btn-secondary').on('click', function() {
    $('#packagesModal').modal('hide')
  })
})

