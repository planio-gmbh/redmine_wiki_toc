if Redmine::VERSION::MAJOR >= 2
  RedmineApp::Application.routes.draw do
    get 'projects/:project_id/wiki_toc', :to => 'wiki#table_of_contents'
    post 'projects/:project_id/wiki/:id/reorder', :to => 'wiki_toc#reorder'
  end
else
  ActionController::Routing::Routes.draw do |map|
    map.with_options :path_prefix => 'projects/:project_id' do |p|
      p.connect '/wiki/toc', :controller => 'wiki', :action => 'table_of_contents', :conditions => {:method => :get}
      p.connect '/wiki/:id/reorder', :controller => 'wiki_toc', :action => 'reorder',  :conditions => {:method => :post}
    end
  end
end