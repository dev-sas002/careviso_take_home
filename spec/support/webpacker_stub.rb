# The request specs render real templates, and the layout asks Webpacker for the
# compiled pack. Compiling JavaScript to assert on HTML would make the suite slow
# and would need Node installed just to run `rspec`, so in the test environment
# the two pack helpers return nothing. Everything else about the layout still
# renders, which is what these specs are checking.
module StubbedWebpackerHelpers
  def javascript_pack_tag(*_names, **_options)
    "".html_safe
  end

  def stylesheet_pack_tag(*_names, **_options)
    "".html_safe
  end
end

ActiveSupport.on_load(:action_view) do
  include StubbedWebpackerHelpers
end
