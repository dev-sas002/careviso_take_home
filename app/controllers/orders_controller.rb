class OrdersController < ApplicationController
  before_action :find_order, only: [:show, :edit, :update, :destroy]

  def index
    @orders = Order.all
  end

  def show
  end

  def new
    @order = Order.new
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      flash[:success] = 'Order was successfully created.'
      redirect_to @order
    else
      flash.now[:error] = @order.errors.full_messages.to_sentence
      render :new
    end
  end

  def edit
  end

  def update
    if @order.update(order_params)
      flash[:success] = 'Order was successfully updated.'
      redirect_to @order
    else
      flash.now[:error] = @order.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_path
  end

  private

  def find_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(product_ids: [])
  end
end
