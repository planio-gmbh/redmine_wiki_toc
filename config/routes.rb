RedmineApp::Application.routes.draw do
  get 'projects/:project_id/wiki_toc', :to => 'wiki#table_of_contents'
  post 'projects/:project_id/wiki/:id/reorder', :to => 'wiki_toc#reorder'
end