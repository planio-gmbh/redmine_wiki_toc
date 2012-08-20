module RedmineWikiToc
  module WikiPagePatch
    extend ActiveSupport::Concern

    included do
      acts_as_list :scope => 'parent_id #{parent_id ? "= #{parent_id}" : "IS NULL"} AND wiki_id = #{wiki_id}'

      before_save lambda { |p| p.generate_number if p.position_changed? }
      before_create lambda { |p| p.generate_number }

      alias_method_chain :pretty_title, :number
      class_attribute :number_prefix_disabled_tmp

      safe_attributes 'position', 'move_to',
        :if => lambda {|page, user| page.new_record? || user.allowed_to?(:reorder_wiki_pages, page.project, :object => page)}

      alias_method_chain :move_to_bottom, :number_assign
      alias_method_chain :move_to_top, :number_assign
    end

    def number_prefix
      !number_prefix_disabled? && number.present? ? number+". " : ""
    end

    def number_prefix_disabled?
      self.class.number_prefix_disabled_tmp? || !project.module_enabled?(:wiki_toc)
    end

    def pretty_title_with_number
      number_prefix + pretty_title_without_number
    end

    def move_to_top_with_number_assign
      move_to_top_without_number_assign
      self.class.regenerate_numbers(wiki, parent_id)
    end

    def move_to_bottom_with_number_assign
      move_to_bottom_without_number_assign
      self.class.regenerate_numbers(wiki, parent_id)
    end

    module ClassMethods
      def regenerate_numbers(wiki, parent_id)
        wiki.pages.where(:parent_id => parent_id).each { |p| p.generate_number; p.save }
      end
      def with_disabled_number_prefix
        self.number_prefix_disabled_tmp = true
        result = yield
        self.number_prefix_disabled_tmp = false
        result
      end
    end

    def assign_number(parent = nil)
      parent ||= self.parent
      self.number = (parent && parent.number.present? && parent.number+"." || "")+position.to_s
    end

    def generate_number
      assign_number
      return unless number_changed?
      parents = {id => self}
      descendants.each do |c|
        parent = parents[c.parent_id] ||= c.parent.reload
        c.assign_number(parent)
        c.save
      end
    end
  end
end