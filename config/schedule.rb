every 24.hours do
  rake "redmine:backlogs:generate_chart_data"
end

every 15.minutes do
  rake "redmine:email:receive_imap host=imap.gmail.com port=993 username=redmine@cramerdev.com password=zxasqw12cvdfer34 ssl=true project=newhires unknown_user=accept no_permission_check=1"
end

every 15.minutes do
  rake "redmine:email:receive_imap host=imap.gmail.com port=993 username=collegedegrees-ticket@cramerdev.com password=iewahL1i ssl=true project=cd-schools unknown_user=accept no_permission_check=1"
end
