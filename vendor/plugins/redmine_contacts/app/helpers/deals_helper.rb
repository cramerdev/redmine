module DealsHelper
  
  def retrieve_date_range(period)   
    @from, @to = nil, nil
    case period 
    when 'today'
      @from = @to = Date.today
    when 'yesterday'
      @from = @to = Date.today - 1
    when 'current_week'
      @from = Date.today - (Date.today.cwday - 1)%7
      @to = @from + 6
    when 'last_week'
      @from = Date.today - 7 - (Date.today.cwday - 1)%7
      @to = @from + 6
    when '7_days'
      @from = Date.today - 7
      @to = Date.today
    when 'current_month'
      @from = Date.civil(Date.today.year, Date.today.month, 1)
      @to = (@from >> 1) - 1
    when 'last_month'
      @from = Date.civil(Date.today.year, Date.today.month, 1) << 1
      @to = (@from >> 1) - 1
    when '30_days'
      @from = Date.today - 30
      @to = Date.today
    when 'current_year'
      @from = Date.civil(Date.today.year, 1, 1)
      @to = Date.civil(Date.today.year, 12, 31)
    end    
    
    @from, @to = @from, @to + 1 if (@from && @to)
        
  end
  
  def retrieve_deals_query
    # debugger
    # params.merge!(session[:deals_query])
    # session[:deals_query] = {:project_id => @project.id, :status_id => params[:status_id], :category_id => params[:category_id], :assigned_to_id => params[:assigned_to_id]}
    if params[:status_id] || !params[:period].blank? || !params[:category_id].blank? || !params[:assigned_to_id].blank? 
      session[:deals_query] = {:project_id => (@project ? @project.id : nil), 
                               :status_id => params[:status_id], 
                               :category_id => params[:category_id], 
                               :period => params[:period],
                               :assigned_to_id => params[:assigned_to_id]}
    else
      if api_request? || params[:set_filter] || session[:deals_query].nil? || session[:deals_query][:project_id] != (@project ? @project.id : nil)
        session[:deals_query] = {}
      else
        params.merge!(session[:deals_query])
      end
    end
  end
  
  
end
