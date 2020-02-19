class KeywordMappingsController < ApplicationController
  before_action :set_keyword_mapping, only: [:show, :edit, :update, :destroy]

  # GET /keyword_mappings
  # GET /keyword_mappings.json
  def index
    @keyword_mappings = KeywordMapping.page(params[:page]).per(50)
  end

  # GET /keyword_mappings/1
  # GET /keyword_mappings/1.json
  def show
  end

  # GET /keyword_mappings/new
  def new
    @keyword_mapping = KeywordMapping.new
  end

  # GET /keyword_mappings/1/edit
  def edit
  end

  # POST /keyword_mappings
  # POST /keyword_mappings.json
  def create
    @keyword_mapping = KeywordMapping.new(keyword_mapping_params)

    respond_to do |format|
      if @keyword_mapping.save
        format.html { redirect_to keyword_mappings_url, notice: '新建成功 ヽ(✿ﾟ▽ﾟ)ノ' }
        format.json { render :show, status: :created, location: @keyword_mapping }
      else
        format.html { render :new }
        format.json { render json: @keyword_mapping.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /keyword_mappings/1
  # PATCH/PUT /keyword_mappings/1.json
  def update
    respond_to do |format|
      if @keyword_mapping.update(keyword_mapping_params)
        format.html { redirect_to @keyword_mapping, notice: '更新成功 ｡:.ﾟヽ(*´∀`)ﾉﾟ.:｡' }
        format.json { render :show, status: :ok, location: @keyword_mapping }
      else
        format.html { render :edit }
        format.json { render json: @keyword_mapping.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /keyword_mappings/1
  # DELETE /keyword_mappings/1.json
  def destroy
    @keyword_mapping.destroy
    respond_to do |format|
      format.html { redirect_to keyword_mappings_url, notice: '刪除成功 ε٩(๑> ₃ <)۶з' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_keyword_mapping
      @keyword_mapping = KeywordMapping.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def keyword_mapping_params
      params.require(:keyword_mapping).permit(:keyword, :message)
    end
end