class StartupsController < InheritedResources::Base
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:confirm_employee, :confirm_startup_link]
  after_filter only: [:create] do
    @startup.founders << current_user
    @startup.save
  end

  def index
    @current_user = current_user
    if current_user.startup.present?
      redirect_to action: :show, id: current_user.startup.id
    else
      redirect_to action: :new
    end
  end

  def create
    @startup = Startup.create(apply_now_params.merge({email: current_user.email}))
    @startup.full_validation = false
    @startup.founders << current_user
    if @startup.save
      # flash[:notice] = "Your startup Application is submited and in pending for approval."
      render :post_create
      StartupMailer.apply_now(@startup).deliver
    end
  end

  def show
    @startup = Startup.find(params[:id])
    raise_not_found unless current_user.startup.try(:id) == @startup.id
  end

  def edit
    @startup = Startup.find(params[:id])
    @current_user = current_user
    raise_not_found unless current_user.startup.try(:id) == @startup.id
    raise_not_found unless current_user.is_founder?
  end

  def update
    update! do |success, failure|
      success.html {
        StartupMailer.notify_svrep_about_startup_update(@startup).deliver
        StartupMailer.fill_personal_info_for_director(@startup).deliver
        @startup.directors.each do |user|
          message = "Please fill in personl info"
          UserPushNotifyJob.new.async.perform(user.id, :fill_personal_info, message)
        end
        redirect_to startup_founders_url(@startup)
      }
    end
  end

  def confirm_startup_link
    @startup = Startup.find(params[:id])
    @self = User.find_by_startup_verifier_token(params[:token])
    raise_not_found unless @self
    @startup.founders << @self
    @self.confirm_employee! true
  end

  def confirm_employee
    @startup = Startup.find(params[:id])
    @new_employee = User.find_by_startup_verifier_token(params[:token])
    raise_not_found unless @new_employee
    if request.post?
      flash[:notice] = "User was already accepted as startup employee." if @new_employee.startup_link_verifier_id
      @new_employee.confirm_employee! params[:is_founder]
      message = "Congratulations! You've been approved as #{@new_employee.title} at #{@startup.name}."
      UserMailer.accepted_as_employee(@new_employee, @startup).deliver
      UserPushNotifyJob.new.async.perform(@new_employee.id, :confirm_employee, message)
      render :confirm_employee_done
    else
      @token = params[:token]
      render :confirm_employee
    end
  end

  def apply_now_params
    params.require(:startup).permit(:name, :phone, :pitch, :website, :email)
  end

  def permitted_params
    {:startup => params.fetch(:startup, {}).permit(:name, :address, :pitch, :website, :about, :email, :phone, :logo, {help_from_sv: []},
                                                   :remote_logo_url, :facebook_link, :twitter_link, :pre_funds, :pre_investers_name,
                                                   :help_from_sv, {category_ids: []}, {founders_attributes: [:id, :title]},
                                                   {startup_before: [:startup_name, :startup_descripition] }
                                                  )}
  end
end
