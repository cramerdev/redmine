class Contact < ActiveRecord::Base
  unloadable  
  has_many :notes, :as => :source, :dependent => :delete_all, :order => "created_on DESC"
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'    
  has_and_belongs_to_many :issues, :order => "#{Issue.table_name}.due_date", :uniq => true   
  has_and_belongs_to_many :deals, :order => "#{Deal.table_name}.status_id"  
  has_and_belongs_to_many :projects, :uniq => true   
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'   
  has_one :avatar, :class_name => "Attachment", :as  => :container, :conditions => "#{Attachment.table_name}.description = 'avatar'", :dependent => :destroy
  
  attr_accessor :phones     
  attr_accessor :emails 
  
  acts_as_viewable

  acts_as_taggable
  
  acts_as_watchable

  acts_as_attachable :view_permission => :view_contacts,  
                     :delete_permission => :edit_contacts

  acts_as_event :datetime => :created_on,
                :url => Proc.new {|o| {:controller => 'contacts', :action => 'show', :id => o}}, 	
                :type => Proc.new {|o| 'contact' },  
                :title => Proc.new {|o| o.name },
                :description => Proc.new {|o| o.notes }     
                
  named_scope :visible, lambda {|*args| { :include => :projects,
                                          :conditions => Contact.allowed_to_condition(args.first || User.current, :view_contacts) }}                
  named_scope :in_project, lambda {|*args| { :include => :projects, :conditions => ["#{Project.table_name}.id = ?", args.first]}}
  
  named_scope :like_by, lambda {|field, search| {:conditions =>   ["#{Contact.table_name}.#{field} LIKE ?", search + "%"] }}    

  named_scope :live_search, lambda {|search| {:conditions =>   ["(#{Contact.table_name}.first_name LIKE ? or 
                                                                  #{Contact.table_name}.last_name LIKE ? or 
                                                                  #{Contact.table_name}.middle_name LIKE ? or 
                                                                  #{Contact.table_name}.company LIKE ? or 
                                                                  #{Contact.table_name}.job_title LIKE ?)", 
                                                                 "%" + search + "%",
                                                                 "%" + search + "%",
                                                                 "%" + search + "%",
                                                                 "%" + search + "%",
                                                                 "%" + search + "%"] }}
  
  # named_scope :live_search, lambda {|*args| {:conditions =>  args.first.split(' ').collect{ |search_string|
  #                                                                   ["(#{Contact.table_name}.first_name LIKE ? or 
  #                                                                     #{Contact.table_name}.last_name LIKE ? or 
  #                                                                     #{Contact.table_name}.middle_name LIKE ? or 
  #                                                                     #{Contact.table_name}.company LIKE ? or 
  #                                                                     #{Contact.table_name}.job_title LIKE ?)", 
  #                                                                              "%" + search_string + "%",
  #                                                                              "%" + search_string + "%",
  #                                                                              "%" + search_string + "%",
  #                                                                              "%" + search_string + "%",
  #                                                                              "%" + search_string + "%"
  #                                                                              ] }
  #                
  #   }}
  
  named_scope :order_by_name, :order => "#{Contact.table_name}.last_name, #{Contact.table_name}.first_name"               
                
  # name or company is mandatory
  validates_presence_of :first_name 
  validates_uniqueness_of :first_name, :scope => [:last_name, :middle_name, :company]
   
  def self.allowed_to_condition(user, permission, options={})
    Project.allowed_to_condition(user, permission)
  end
  
  def duplicates(limit=5)    
    scope = Contact.scoped({})  
    scope = scope.like_by("first_name",  self.first_name.strip) if !self.first_name.blank?
    scope = scope.like_by("last_name",  self.last_name.strip) if !self.last_name.blank?  
    scope = scope.scoped(:conditions => ["#{Contact.table_name}.id <> ?", self.id]) if !self.new_record? 
    @duplicates ||= (self.first_name.blank? && self.last_name.blank?) ? [] : scope.visible.find(:all, :limit => limit)  
  end
  
  def employees
    @employees ||= Contact.order_by_name.find_all_by_company(self.first_name)
  end

  def contact_company
    @contact_company ||= Contact.find_by_first_name(self.company) 
  end
  
  def notes_attachments 
    @contact_attachments ||= Attachment.find(:all, 
                                    :conditions => { :container_type => "Note", :container_id => self.notes.map(&:id)},   
                                    :order => "created_on DESC")
  end

  
  def visible?(usr=nil)    
    self.projects.map do |project|
      (usr || User.current).allowed_to?(:view_contacts, project)
    end.inject do |memo,allowed|
      memo || allowed
    end
  end   
  
  def self.projects_joins
    joins = []
    joins << ["JOIN contacts_projects ON contacts_projects.contact_id = #{self.table_name}.id"]
    joins << ["JOIN #{Project.table_name} ON contacts_projects.project_id = #{Project.table_name}.id"]
  end

  def project(current_project=nil)     
    return @project if @project
    if current_project && self.projects.visible.include?(current_project) 
      @project  = current_project
    else    
      @project  = self.projects.find(:first, :conditions => Project.allowed_to_condition(User.current, :view_contacts))
    end 
     
    @project ||= self.projects.first
  end
  
  def name
    result = []
    if !self.is_company
      [self.last_name, self.first_name, self.middle_name].each {|field| result << field unless field.blank?}
    else
      result << self.first_name
    end    

    return result.join(" ")
  end   
  
  def info
    self.job_title
  end
     
  def phones                            
    @phones || self.phone ? self.phone.split( /, */) : []
  end   
  
  def emails                            
    @emails || self.email ? self.email.split( /, */) : []
  end
  
  private
  
  def assign_phone      
    if @phones
      self.phone = @phones.uniq.map {|s| s.strip.delete(',').squeeze(" ")}.join(', ')
    end
  end 
  
end
