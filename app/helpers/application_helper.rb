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

  # Which selection algorithm answered, shown on the order page so the choice is
  # visible rather than implicit.
  def selection_strategy_name
    PackageSelection::Registry.default.to_s.humanize.downcase
  end
end
