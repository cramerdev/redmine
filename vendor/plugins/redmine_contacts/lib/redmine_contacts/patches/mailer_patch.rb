require 'dispatcher'   
 
module RedmineContacts
  module Patches    

    module MailerPatch
      module ClassMethods
      end

      module InstanceMethods
        def note_added(note, parent)
          redmine_headers 'X-Project' => note.source.project.identifier, 
                          'X-Notable-Id' => note.source.id,
                          'X-Note-Id' => note.id
          message_id note
          if parent
            recipients (note.source.watcher_recipients + parent.watcher_recipients).uniq
          else
            recipients note.source.watcher_recipients
          end
        
          subject "[#{note.source.project.name}] - #{parent.name + ' - ' if parent}#{l(:label_note_for)} #{note.source.name}"  
      
          body :note => note,   
               :note_url => url_for(:controller => 'notes', :action => 'show', :project_id => note.source.project, :note_id => note.id)
          render_multipart('note_added', body)
        end
    
    def issue_connected(issue, contact)
      redmine_headers 'X-Project' => contact.project.identifier, 
                      'X-Issue-Id' => issue.id,
                      'X-Contact-Id' => contact.id
      message_id contact
      recipients contact.watcher_recipients 
      subject "[#{contact.projects.first.name}] - #{l(:label_issue_for)} #{contact.name}"  
      
          body :contact => contact,
               :issue => issue,
               :contact_url => url_for(:controller => contact.class.name.pluralize.downcase, :action => 'show', :project_id => contact.project, :id => contact.id),
               :issue_url => url_for(:controller => "issues", :action => "show", :id => issue)
          render_multipart('issue_connected', body)
      
        end
    
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
    
  end
end

Dispatcher.to_prepare do  

  unless Mailer.included_modules.include?(RedmineContacts::Patches::MailerPatch)
    Mailer.send(:include, RedmineContacts::Patches::MailerPatch)
  end   

end

