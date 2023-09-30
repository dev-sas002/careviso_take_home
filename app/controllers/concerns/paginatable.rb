# Keeps index actions off the "load every row" path.
#
# The index pages were unbounded: `Product.all` renders fine with the seed data
# and falls over with a real catalogue. This is deliberately a ~20 line concern
# rather than a pagination gem — one `LIMIT/OFFSET` and a page count is the whole
# requirement here, and the dependency would have to be justified to a reviewer.
module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  included do
    helper_method :pagination if respond_to?(:helper_method)
  end

  Pagination = Struct.new(:page, :per_page, :total_count, keyword_init: true) do
    def total_pages
      [(total_count.to_f / per_page).ceil, 1].max
    end

    def first_page?
      page <= 1
    end

    def last_page?
      page >= total_pages
    end

    def offset
      (page - 1) * per_page
    end

    def empty?
      total_count.zero?
    end

    def range
      return 0..0 if empty?

      (offset + 1)..[offset + per_page, total_count].min
    end
  end

  attr_reader :pagination

  private

  # @return [ActiveRecord::Relation] the requested page of `scope`
  def paginate(scope, per_page: DEFAULT_PER_PAGE)
    per_page = per_page.clamp(1, MAX_PER_PAGE)
    total = scope.except(:order, :limit, :offset).count
    @pagination = Pagination.new(page: requested_page, per_page: per_page, total_count: total)

    scope.limit(@pagination.per_page).offset(@pagination.offset)
  end

  def requested_page
    [params[:page].to_i, 1].max
  end
end
