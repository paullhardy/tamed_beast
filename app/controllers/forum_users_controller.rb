class ForumUsersController < TamedBeastController
    
  before_filter :forum_admin_required, :only => [:suspend, :unsuspend, :destroy, :purge, :edit]
  before_filter :find_user, :only => [:update, :show, :edit, :suspend, :unsuspend, :destroy, :purge]
  before_filter :require_user, :only => [:settings, :update]

  # Brainbuster Captcha
  # before_filter :create_brain_buster, :only => [:new]
  # before_filter :validate_brain_buster, :only => [:create]

  def index
    users_scope = forum_admin? ? :all_users : :users
    # Change User with User.send(users_scope)
    if params[:q]
      @users = User.named_like(params[:q]).paginate(:page => current_page)
    else
      @users = User.all.paginate(:page => current_page)
    end
  end

  # # render new.rhtml
  # def new
  # end
  # 
  # def create
  #   cookies.delete :auth_token
  #   @user = User.new(params[:user])    
  #   @user.save if @user.valid?
  #   @user.register! if @user.valid?
  #   unless @user.new_record?
  #     redirect_back_or_default('/login')
  #     flash[:notice] = I18n.t 'txt.activation_required', 
  #       :default => "Thanks for signing up! Please click the link in your email to activate your account"
  #   else
  #     render :action => 'new'
  #   end
  # end
                                         

  def settings
    @user = current_user
    render :action => "edit"
  end
  
  def edit
    @user = find_user
  end

  def update
    @user = forum_admin? ? find_user : current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User account was successfully updated.'
        format.html { redirect_to(settings_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def activate
    # not sure why this was using a symbol. Let's use the real false.
    self.current_user = params[:activation_code].blank? ? false : User.all.find_in_state(:first, :pending, :conditions => {:activation_code => params[:activation_code]})
    if logged_in?
      current_user.activate!
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end

  def suspend
    @user.suspend! 
    flash[:notice] = "User was suspended."
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    flash[:notice] = "User was unsuspended."
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end
  
  def make_forum_admin
    redirect_back_or_default('/') and return unless forum_admin?
    @user = find_user
    @user.forum_admin = (params[:user][:forum_admin] == "1")
    @user.save
    redirect_to @user
  end

protected
  def find_user
    @user = if forum_admin?
      User.find params[:id]
    elsif params[:id] == current_user.id
      current_user
    else
      User.active.find params[:id]
    end or raise ActiveRecord::RecordNotFound
  end

  def authorized?
    forum_admin? || params[:id].blank? || params[:id] == current_user.id.to_s
  end

  def render_or_redirect_for_captcha_failure
    render :action => 'new'
  end
end