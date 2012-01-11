class DealStatus < ActiveRecord::Base
  unloadable

  has_and_belongs_to_many :projects

  acts_as_list

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30
  validates_format_of :name, :with => /^[\w\s\'\-]*$/i

end
