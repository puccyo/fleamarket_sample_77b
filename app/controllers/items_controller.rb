class ItemsController < ApplicationController
  layout 'no-header',only: [:new,:create,:edit,:update]
  before_action :authenticate_user!, only: [:new, :create, :edit, :update,:destroy]
  before_action :set_item,only:[:edit,:update,:destroy]
  before_action :not_useritem,only:[:edit,:update,:destroy]
  before_action :set_parents,except: :destroy
  before_action :set_search, only:[:index, :show]

  def index
    @items = Item.all.includes(:photos).order('created_at DESC').limit(4)
  end

  def show
    @item = Item.find(params[:id])
    @category = @item.category
    @items = @category.set_items
    @items = @items.order("created_at DESC").limit(6)
    @comment = Comment.new
    @comments = @item.comments.includes(:user)
  end

  def new
    @item = Item.new
    @item.photos.new
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      flash[:notice] = "商品を出品しました。"
      redirect_to root_path
    else
      @item.photos.new
      flash.now[:alert] = @item.errors.full_messages
      render :new
    end
  end

  def edit
    @item.photos.new
    @parent = @item.category.parent.parent_id
    @child = @item.category.parent_id
    @children = Category.where(ancestry: "#{@parent}")
    @grandchildren = Category.where(ancestry: "#{@parent}/#{@child}")
  end

  def update
    if @item.update(item_params)
      flash[:notice] = "商品情報を更新しました。"
      redirect_to root_path
    else
      flash.now[:alert] = @item.errors.full_messages
      @item = Item.find(params[:id])
      @item.photos.new
      @parent = @item.category.parent.parent_id
      @child = @item.category.parent_id
      @children = Category.where(ancestry: "#{@parent}")
      @grandchildren = Category.where(ancestry: "#{@parent}/#{@child}")
      render :new
    end
  end

  def destroy
    @item.destroy
    flash[:notice] = "商品を削除しました。"
    redirect_to root_url
  end

  def children
    respond_to do |format|
      format.json do
        @children = Category.find(params[:id]).children
      end
    end
  end


  def grandchildren
    respond_to do |format|
      format.json do
        @grandchildren = Category.find(params[:id]).children
      end
    end
  end


  def grandchildrenancestry
    respond_to do |format|
      format.json do
        @grandchildren = Category.where(ancestry: params[:ancestry])
      end
    end
  end

  private

  def set_search
    @search = Item.ransack(params[:q])
  end

  def item_params
    params.require(:item).permit(:name,  :price, :size_id, :category_id,:description, :item_condition_id, :burden_id, :prefectures_id, :days_id, :brand,  photos_attributes: [:image, :_destroy, :id]).merge(user_id: current_user.id)
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def not_useritem
    if @item.user_id != current_user.id
      redirect_to root_url
    end
  end

  def set_parents
    @parents = Category.where(ancestry: nil)
  end

end

