class WikiTocController < ApplicationController
  unloadable

  before_filter :find_wiki
  before_filter :find_existing_page, :only => [:reorder]
  before_filter :authorize

  def reorder
    @page.update_attributes(params[:page])
    @parent = @page.parent
    @pages = @parent ? @parent.descendants : @wiki.pages
    @pages = @pages.sort.group_by(&:parent_id)
    @depth = params[:depth].to_i if params[:depth]
    respond_to do |format|
      format.js
    end
  end

private

  def find_wiki
    @project = Project.find(params[:project_id])
    @wiki = @project.wiki
    render_404 unless @wiki
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Finds the requested page and returns a 404 error if it doesn't exist
  def find_existing_page
    @page = @wiki.find_page(params[:id])
    if @page.nil?
      render_404
    end
  end
end
