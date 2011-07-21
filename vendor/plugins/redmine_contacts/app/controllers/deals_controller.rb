class DealsController < ApplicationController
  unloadable     
  
  PRICE_TYPE_PULLDOWN = [l(:label_price_fixed_bid), l(:label_price_per_hour)]
  
  before_filter :find_deal, :only => [:show, :edit, :update, :destroy] 
  before_filter :find_project_by_project_id, :only => [:new, :create]
  before_filter :authorize, :except => [:index]
  before_filter :find_optional_project, :only => [:index]   
  before_filter :find_deals, :only => :index
      
  before_filter :update_deal_from_params, :only => [:edit, :update]
  before_filter :build_new_deal_from_params, :only => [:new, :create]  
  before_filter :find_deal_attachments, :only => :show
 
  helper :attachments
  helper :contacts
  helper :notes  
  helper :watchers  
  include WatchersHelper
  
  def new
    @deal = Deal.new  
    @deal.contacts = [Contact.find(params[:contact_id])] if params[:contact_id] 
    if @contacts.empty?
      redirect_to :action => "index", :project_id  =>  @project     
    end  
  end

  def create   
    @deal = Deal.new(params[:deal])  
    @deal.contacts = [Contact.find(params[:contacts])]
    @deal.project = @project 
    @deal.author = User.current      
    if @deal.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => "show", :project_id => params[:project_id], :id => @deal
    else
      render :action => "new"   
    end
  end
  
  def update  
    if @deal.update_attributes(params[:deal]) 
      @deal.contacts = [Contact.find(params[:contacts])] if params[:contacts]
      flash[:notice] = l(:notice_successful_update)  
      respond_to do |format| 
        format.html { redirect_to :action => "show", :id => @deal, :project_id => params[:project_id]} 
        format.xml  { } 
      end  
    else           
      respond_to do |format|
        format.html { render :action => "edit"}
      end
    end
    
  end
  
  def edit   
    respond_to do |format|
      format.html { }
      format.xml  { }
    end
  end

  def index    
    last_notes  
    respond_to do |format|
      format.html { render :partial => "list", :layout => false, :locals => {:deals => @deals} if request.xhr? } 
      format.xml { render :xml => @deals}  
      format.json { render :text => @deals.to_json, :layout => false } 
    end

    
    
  end

  def show
    respond_to do |format|
      format.html { @deal.viewed }
      format.xml  { }
    end
  end

  def destroy  
    if @deal.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    redirect_to :action => "index", :project_id => params[:project_id]
    
  end

  private

  def last_notes(count=5)      
    # TODO: Исправить говнокод этот и выделить все в плагин acts-as-noteble
      @last_notes = Note.find(:all, 
                                 :conditions => { :source_type => "Deal", :source_id => find_deals.map(&:id)}, 
                                 :limit => count,
                                 :order => "created_on DESC").collect{|obj| obj if obj.source.visible?}.compact                    
  end

  
  def build_new_deal_from_params
    find_contacts
  end
  
  def update_deal_from_params
    find_contacts  
  end
 
  def find_contacts    
    @contacts =  @project.contacts
  end
  
  def find_deal_attachments 
    @deal_attachments = Attachment.find(:all, 
                                    :conditions => { :container_type => "Note", :container_id => @deal.notes.map(&:id)},   
                                    :order => "created_on DESC")
  end
  
  
  def find_deals     
    cond = "1 = 1"
    cond << " and #{Deal.table_name}.project_id = #{@project.id}" if @project
    cond << " and #{Deal.table_name}.status_id = #{params[:deal_status_id]}" if !params[:deal_status_id].blank?

    # debugger
    @deals = Deal.visible.find(:all, :conditions => cond, :order => :status_id, :include => [:contacts, :project] )
  end
  
  def find_deal
    @deal = Deal.find(params[:id], :include => :project)
    @project ||= @deal.project
    if !(params[:project_id] == @project.identifier)
      params[:project_id] = @project.identifier     
      redirect_to params
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
end
