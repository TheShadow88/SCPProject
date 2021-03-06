class FacilitiesController < ApplicationController
  # acts_as_token_authentication_handler_for User, fallback: :permission_denied
  before_action :set_facility, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token
  # GET /facilities
  # GET /facilities.json

  def permission_denied
    redirect_to(root_path, status: 401)
  end

  def index
    id = params[:id]
    @facilities = pagination("facilities", "facilities.Name")
      if(params[:api])
        js = []
        @facilities.each do |fac|
          puts fac
          js.push(
            { 
                 "name" => fac["name"],
                 "capacity" => fac["capacity"],
                 "Id" => fac["id"]
              })
          
          
        end
        render json: { 
                 "facilities" => js
              }.to_json, status: 200
    end
      # puts @facilities[0]["id"]
  end

  # GET /facilities/1
  # GET /facilities/1.json
  def show
    id = params[:id]
    query = "SELECT fac.name, fac.capacity, ac.Name as AnomalyClass 
             FROM facilities fac
             INNER JOIN AnomalyClass ac ON ac.Id = fac.ClassId
             WHERE fac.Id = ?"

    vals = [[nil, id]]
    @facility = ActiveRecord::Base.connection.exec_insert(query, "show", vals)[0]
    query = "SELECT sc.Id, sc.Name 
             FROM SCP sc
             INNER JOIN facilities fac ON fac.Id = sc.FacilityContainedId
             WHERE fac.Id = ?"
    @scps = ActiveRecord::Base.connection.exec_query(query, "scp query", vals)
    # @staff = []

    query = "SELECT st.name, st.id
             FROM staffs st
             INNER JOIN facilities fac ON fac.Id = st.FacilityId
             WHERE fac.Id = ?"
   @staff = ActiveRecord::Base.connection.exec_query(query, "staff query", vals)

   if(params[:api])
      render json: { 
             "name" => @facility["name"],
             "capacity" => @facility["capacity"],
             "Anomaly class" => @facility["AnomalyClass"],
             "scps" => @scps.map { |sc| sc["Name"] },
             "staff" => @staff.map { |st| st["name"]}
          }.to_json, status: 200
      return
    end

  end

  # GET /facilities/new
  def new
    @facility = Facility.new
    class_query = "SELECT Id, Name FROM AnomalyClass;"
    @anomaly_classes = ActiveRecord::Base.connection.execute(class_query)
  end

  # GET /facilities/1/edit
  def edit
    clearance_query = "SELECT Level, Name FROM SecurityClearance;"
    @clearance_levels = ActiveRecord::Base.connection.execute(clearance_query)

    class_query = "SELECT Id, Name FROM AnomalyClass;"
    @anomaly_classes = ActiveRecord::Base.connection.execute(class_query)

    facility_query = "SELECT id, name FROM facilities;"
    @facilities = ActiveRecord::Base.connection.execute(facility_query)
  end

  # POST /facilities
  # POST /facilities.json
  def create
    if(params["api"])
      name = params[:name]
      capacity = params[:capacity]
      anomaly_class = params[:anomaly_class]
    else
      name = params[:facility][:name]
      capacity = params[:facility][:capacity]
      anomaly_class = params[:anomaly_class]
    end
    # query = "INSERT INTO staffs(name, age, position, created_at, updated_at) VALUES('" + name +  "',"+ age +",'"+ position +"', '', '')"
      query = "INSERT INTO facilities(id, name, capacity, ClassId) VALUES(NULL, ?, ?, ?)"
      # vals = [ActiveRecord::Relation::QueryAttribute.new("String", name, Type::Value.new), Relation::QueryAttribute.new("number", age, Type::Value.new), 
      #   Relation::QueryAttribute.new("String", position, Type::Value.new)]
      vals = [[nil, name], [nil, capacity], [nil, anomaly_class]]
    result = ActiveRecord::Base.connection.exec_insert(query, "insert facility", vals)
    query = "SELECT last_insert_rowid() as last" 
    id = ActiveRecord::Base.connection.exec_query(query, "insert facility", [])
    id_to_return = id[0]["last"]
    ur = request.original_url
    if(params["api"])
      head :created, location: ur[0, ur.index("?")] + "/" + id_to_return.to_s
      return
    else
      redirect_to facilities_path()
    end
  end

  # PATCH/PUT /facilities/1
  # PATCH/PUT /facilities/1.json
  def update # add anomaly class update
    id = params[:id]
    anomaly_class = params["anomaly_class"]
    if(params["api"])
      name = params[:name]
      capacity = params[:capacity]
    else
    name = params[:facility][:name]
    capacity = params[:facility][:capacity]
      
    end
    query = "UPDATE facilities SET name=?, ClassId=?, capacity=? where id = ?;"
    vals = [[nil, name], [nil, anomaly_class], [nil, capacity],  [nil, id]]
    result = ActiveRecord::Base.connection.exec_update(query, "update facility", vals)
    if(params["api"])
      head :ok
      return
    else
      redirect_to facility_path(id)
    end
  end

  # DELETE /facilities/1
  # DELETE /facilities/1.json
  def destroy
    if(params["api"])
      id = params[:id]
    else
      id = @facility.id
    end
    query = "DELETE FROM facilities WHERE id = ?;"
    vals = [[nil, id]]
    result = ActiveRecord::Base.connection.exec_delete(query, "delete facility", vals)
    if(params["api"])
      head :ok
      return
    end
    respond_to do |format|
      format.html { redirect_to facilities_url, notice: 'Facility was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_facility
      @facility = Facility.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def facility_params
      params.require(:facility).permit(:name, :capacity)
    end
end
