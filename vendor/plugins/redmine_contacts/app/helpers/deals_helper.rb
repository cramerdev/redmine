module DealsHelper
  def collection_for_status_select
    values = Deal::STATUSES  
    values.keys.sort{|x,y| values[x][:order] <=> values[y][:order]}.collect{|k| [l(values[k][:name]), k.to_s]}.insert(0, [""])
  end 
  
  def deal_status_options_for_select(select="")    
     options_for_select(collection_for_status_select, select)
  end
end
