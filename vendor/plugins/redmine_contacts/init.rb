# Redmine contact plugin

config.gem "acts-as-taggable-on", :version => '2.0.6'

begin
  require_library_or_gem 'RMagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

require 'redmine'    
require 'redmine_contacts/patches/contacts_issue_patch'
require 'redmine_contacts/patches/attachments_patch'
require 'redmine_contacts/patches/mailer_patch'
require 'redmine_contacts/wiki_macros/contacts_wiki_macros'  
require 'redmine_contacts/hooks/show_issue_contacts_hook'       
require 'acts_as_viewable/init' 

RAILS_DEFAULT_LOGGER.info 'Starting Contact plugin for RedMine'

Redmine::Plugin.register :contacts do
  name 'Contacts plugin'
  author 'Kirill Bezrukov'
  description 'This is a plugin for Redmine that can be used to track basic contacts information'
  version '1.2.1  '

  author_url 'mailto:kirill.bezrukov@gmail.com' if respond_to? :author_url

  requires_redmine :version_or_higher => '1.0.0'   
  
  settings :default => {
    :use_gravatars => false, 
    :auto_thumbnails  => false,
    :max_thumbnail_file_size => 300
  }, :partial => 'settings/contacts'
  
  
  project_module :contacts_module do
    permission :view_contacts, :contacts => [:show, 
                                             :index, 
                                             :live_search, 
                                             :contacts_notes, 
                                             ],
                               :contacts_tasks => :index, 
                               :notes => [:show]

    permission :edit_contacts, :contacts => [:edit, 
                                             :update, 
                                             :new, 
                                             :create,
                                             :edit_tags],
                                :notes => [:add_note, :destroy, :edit, :update],
                                :contacts_tasks => [:new, :add, :delete, :close],
                                :contacts_duplicates => [:index, :merge, :duplicates],
                                :contacts_projects => [:add, :delete]
                                               
    permission :add_notes, :notes => :add_note   
    permission :delete_notes, :notes => [:destroy, :edit, :update]
    permission :delete_own_notes, :notes => [:destroy, :edit, :update]                                      
    permission :delete_contacts, :contacts => [:destroy]
    permission :delete_deals, :deals => :destroy    
    
    permission :view_deals, :deals => [:index, :show], :public => true
    permission :edit_deals, :deals => [:new, 
                                       :create, 
                                       :edit, 
                                       :update,
                                       :add_attachment],
                         :notes =>  [:add_note, :destroy_note]
    
  end

  menu :project_menu, :contacts, {:controller => 'contacts', :action => 'index'}, :caption => :contacts_title, :param => :project_id
  # menu :project_menu, :deals, { :controller => 'deals', :action => 'index' }, :caption => :label_deal_plural, :param => :project_id
  
  menu :top_menu, :contacts, {:controller => 'contacts', :action => 'index'}, :caption => :contacts_title
  
  activity_provider :contacts, :class_name => ['Note']

  # activity_provider :contacts, :default => false   
end

