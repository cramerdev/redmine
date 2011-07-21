class ContactsController < ApplicationController
  unloadable    
  
  Mime::Type.register "text/x-vcard", :vcf     
  
  default_search_scope :contacts    
  
  before_filter :find_contact, :only => [:show, :edit, :update, :destroy, :edit_tags]  
  before_filter :find_project_by_project_id, :only => [:new, :create]
  before_filter :authorize, :except => [:index, :contacts_notes]
  before_filter :find_optional_project, :only => [:index, :contacts_notes] 
   
  accept_key_auth :index, :show, :create, :update, :destroy
  
  helper :attachments
  helper :contacts  
  helper :watchers  
  helper :notes
  include WatchersHelper
  
  def show   
    @open_issues = @contact.issues.visible.open(:order => "#{Issue.table_name}.due_date DESC")   
    source_id_cond = @contact.is_company ? Contact.order_by_name.find_all_by_company(@contact.first_name).map(&:id) << @contact.id : @contact.id 
    @notes_pages, @notes = paginate :notes,
                                    :per_page => 30,
                                    :conditions => {:source_id  => source_id_cond,  
                                                   :source_type => 'Contact'},
                                    :include => [:attachments],               
                                    :order => "created_on DESC" 

    respond_to do |format|
      format.js if request.xhr?
      format.html { @contact.viewed }
      format.xml { render :xml => @contact }   
      format.json { render :text => @contact.to_json, :layout => false } 
      format.vcf { send_data(contact_to_vcard(@contact), :filename => "#{@contact.name}.vcf", :type => 'text/x-vcard;', :disposition => 'attachment') }            
    end
  end
  
  def index 
    if !request.xhr?
      last_notes
      find_tags       
    end
    find_contacts  
    @contacts.sort! {|x, y| x.name <=> y.name }     
    respond_to do |format|   
      format.html { render :partial => "list", :layout => false, :locals => {:contacts => @contacts} if request.xhr? } 
      format.xml { render :xml => find_contacts(false) }  
      format.json { render :text => find_contacts(false).to_json, :layout => false } 
    end
  end
  
  def edit    
  end

  def update  
    if @contact.update_attributes(params[:contact])
      flash[:notice] = l(:notice_successful_update)     
      attach_avatar
      redirect_to :action => "show", :project_id => params[:project_id], :id => @contact
    else
      render "edit", :project_id => params[:project_id], :id => @contact  
    end
  end

  def destroy
    if @contact.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    redirect_to :action => "index", :project_id => params[:project_id]
  end
  
  def new  
    @duplicates = []
    @contact = Contact.new   
    @contact.company = params[:company_name] if params[:company_name] 
  end

  def create
    @contact = Contact.new(params[:contact])
    @contact.projects << @project 
    @contact.author = User.current
    if @contact.save
      flash[:notice] = l(:notice_successful_create)
      attach_avatar
      redirect_to :action => "show", :project_id => params[:project_id], :id => @contact
    else  
      render :action => "new"
    end
  end

 
  def edit_tags   
    @contact.tags.clear
    @contact.update_attributes(params[:contact])
    respond_to do |format|
      format.js if request.xhr?
      format.html {redirect_to :action => 'show', :id => @contact, :project_id => @project}
    end
  end
  
  def contacts_notes   
    unless request.xhr?  
      find_tags
    end  
    # @notes = Comment.find(:all, 
    #                            :conditions => { :commented_type => "Contact", :commented_id => find_contacts.map(&:id)}, 
    #                            :order => "updated_on DESC")  
   
    joins = " "
    joins << " LEFT OUTER JOIN #{Contact.table_name} ON #{Note.table_name}.source_id = #{Contact.table_name}.id AND #{Note.table_name}.source_type = 'Contact' "
    joins << " LEFT OUTER JOIN #{Deal.table_name} ON #{Note.table_name}.source_id = #{Deal.table_name}.id AND #{Note.table_name}.source_type = 'Deal' "

    cond = "(1 = 1) " 
    cond << "and (#{Contact.table_name}.id in (#{find_contacts(false).any? ? @contacts.map(&:id).join(', ') : 'NULL'})"
    cond << " or #{Deal.table_name}.id in (#{find_deals.any? ? @deals.map(&:id).join(', ') : 'NULL'}))"    
    cond << " and (#{Note.table_name}.content LIKE '%#{params[:search_note]}%')" if params[:search_note] and request.xhr?
   
    @notes_pages, @notes = paginate :notes,
                                    :per_page => 20, 
                                    :joins => joins,      
                                    :conditions => cond, 
                                    :order => "created_on DESC"   
    @notes.compact!   
    
    
    respond_to do |format|   
      format.html { render :partial => "notes/notes_list", :layout => false, :locals => {:notes => @notes, :notes_pages => @notes_pages} if request.xhr?} 
      format.xml { render :xml => @notes }  
    end
  end

  
private      
  def attach_avatar
    @contact.avatar.destroy if @contact.avatar
    if params[:contact_avatar]    
      params[:contact_avatar][:description] = 'avatar'     
      Attachment.attach_files(@contact, {"1" => params[:contact_avatar]})  
      render_attachment_warning_if_needed(@contact)    
    end
  end

  def last_notes(count=5)    
    # @last_notes = find_contacts(false).find(:all, :include => :notes, :limit => count,  :order => 'notes.created_on DESC').map{|c| c.notes}.flatten.first(count)
     
    @last_notes = Note.find(:all, 
                                :conditions => { :source_type => "Contact", :source_id => find_contacts(false).map(&:id).uniq }, 
                                :limit => count,
                                :order => "created_on DESC")                  
    # @last_notes = []                            
  end
  
  def find_contact                                                         
    @contact = Contact.find(params[:id], :include => [:tags])   
    @project = (@contact.projects.visible.find(params[:project_id]) rescue false) if params[:project_id]
    @project ||= @contact.project 
    if !(params[:project_id] == @project.identifier)
      params[:project_id] = @project.identifier     
      redirect_to params
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_tags     
    cond  = ARCondition.new  
    cond << ["#{Project.table_name}.id = ?", @project.id] if @project
    cond << [Contact.allowed_to_condition(User.current, :view_contacts)]   
                                                                                   
    joins = []
    joins << "JOIN #{ActsAsTaggableOn::Tagging.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id "
    joins << "JOIN #{Contact.table_name} ON #{Contact.table_name}.id = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type =  '#{Contact.class_name}' " 
    joins << Contact.projects_joins
    
    options = {}
    options[:select] = "#{ActsAsTaggableOn::Tag.table_name}.*, COUNT(DISTINCT #{ActsAsTaggableOn::Tagging.table_name}.taggable_id) AS count"
    options[:conditions] = cond.conditions  
    options[:joins] = joins.flatten   
    options[:group] = "#{ActsAsTaggableOn::Tag.table_name}.id"
    options[:order] = "#{ActsAsTaggableOn::Tag.table_name}.name"
    
         
    @tags = ActsAsTaggableOn::Tag.find(:all, options) 
  end
  
  def find_deals   
    cond  = ARCondition.new         
    cond << ["#{Deal.table_name}.project_id = ?", @project.id] if @project  
    cond << ["#{Deal.table_name}.name LIKE ? ", "%" + params[:search] + "%"] if params[:search]  

    cond << ["1=0"] if params[:tag]
      
    @deals = Deal.visible.find(:all, :conditions => cond.conditions) || []
  end
  
  def find_contacts(pages=true)   
    @tag = ActsAsTaggableOn::TagList.from(params[:tag]).map{|tag| ActsAsTaggableOn::Tag.find_by_name(tag) } unless params[:tag].blank? 

    cond  = ARCondition.new      
    cond << ["#{Contact.table_name}.job_title = ?", params[:job_title]] unless params[:job_title].blank? 
    cond << ["#{Contact.table_name}.assigned_to_id = ?", params[:user]] unless params[:user].blank? 
    cond << ["#{Contact.table_name}.is_company = ?", params[:is_company]] unless params[:is_company].blank?   
                                                             
    scope = Contact.scoped({}) 
    scope = scope.in_project(@project.id) if @project  
    params[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } if !params[:search].blank? 
    scope = scope.visible
    
    scope = scope.tagged_with(params[:tag]) if !params[:tag].blank?  
    scope = scope.scoped(:conditions => cond.conditions)
    scope = scope.order_by_name
      
    if pages  
      @contacts_pages = Paginator.new(self, scope.count, 20, params[:page])     
      offset = @contacts_pages.current.offset  
      limit =  @contacts_pages.items_per_page
      scope = scope.scoped :include => [:tags, :avatar], :limit  => limit, :offset => offset if @contacts_pages.count > 1
    end
    
    @contacts = scope
  end     
  
end
