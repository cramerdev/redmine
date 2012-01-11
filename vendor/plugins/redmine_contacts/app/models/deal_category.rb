class DealCategory < ActiveRecord::Base
  unloadable      
  belongs_to :project
  has_many :deals, :foreign_key => 'category_id', :dependent => :nullify
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 30

end
