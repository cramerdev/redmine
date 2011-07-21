include ContactsHelper           
include NotesHelper

module RedmineContacts
  module WikiMacros

    Redmine::WikiFormatting::Macros.register do
      desc "Contact Description Macro" 
      macro :contact_plain do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        contact = Contact.find(args.first)
        link_to_source(contact)
      end  

      desc "Contact with avatar"
      macro :contact_avatar do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        contact = Contact.find(args.first)
        link_to avatar_to(contact, :size => "32"),  contact_url(contact), :id => "avatar", :title => contact.name
      end  

      desc "Contact with avatar"
      macro :contact do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        contact = Contact.find(args.first)
        link_to(avatar_to(contact, :size => "16"),  contact_url(contact), :id => "avatar") + ' ' + link_to_source(contact)
      end  

      desc "Deal"
      macro :deal do |obj, args|
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size != 1
        deal = Deal.find(args.first)                                 
        link_title = ''
        link_title += deal.contacts.first.name + ": " if deal.contacts.any?   
        link_title += deal.name
        link_title += " - " + number_to_currency(deal.price) unless deal.price.blank? 
        link_title += ", " + deal.status
        link_to link_title, note_source_url(deal)
      end  

      desc "Thumbnails"
      macro :thumbnails do |obj, args|
        return "" if obj.blank?
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size > 1  
        
        size = ""
        size = args.first if args.any?
        options[:size] = size.blank? ? "100" : size  
        options[:class] = "thumbnail"

        s = '<style type="text/css"> 
        img.thumbnail {
          border: 1px solid #D7D7D7;
          padding: 4px; 
          margin: 4px;
          vertical-align: middle;
        } 
        </style>'  
        
        s << thumbnails(obj, options) 
        content_tag(:p, s) if !s.blank?
        
      end  

    end  

  end
end
