module ApplicationHelper
  FLASH_CLASSES = {
    "success" => "success",
    "error" => "danger",
    "alert" => "warning",
    "notice" => "info"
  }.freeze

  def bootstrap_class_for(flash_type)
    FLASH_CLASSES.fetch(flash_type.to_s, flash_type.to_s)
  end

  # A real form rather than a link with data-method, so deleting works with
  # JavaScript off; rails-ujs still adds the confirm dialog when it is on.
  def delete_button(record, confirm:, label: "Delete")
    button_to label, record, method: :delete,
                             class: "btn btn-sm btn-outline-danger",
                             form: { class: "d-inline-block", data: { confirm: confirm } }
  end

  # Which selection algorithm answered, shown on the order page so the choice is
  # visible rather than implicit.
  def selection_strategy_name
    PackageSelection::Registry.default.to_s.humanize.downcase
  end
end
