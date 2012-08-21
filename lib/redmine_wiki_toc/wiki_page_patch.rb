module RedmineWikiToc
  module WikiPagePatch
    extend ActiveSupport::Concern

    included do
      acts_as_list :scope => 'parent_id #{parent_id ? "= #{parent_id}" : "IS NULL"} AND wiki_id = #{wiki_id}'

      before_save :update_number
      before_create :generate_number

      alias_method_chain :pretty_title, :number
      class_attribute :number_prefix_disabled_tmp

      safe_attributes 'position', 'move_to',
        :if => lambda {|page, user| page.new_record? || user.allowed_to?(:reorder_wiki_pages, page.project, :object => page)}

      alias_method_chain :decrement_positions_on_higher_items, :number_assign
      alias_method_chain :decrement_positions_on_lower_items, :number_assign
      alias_method_chain :increment_positions_on_higher_items, :number_assign
      alias_method_chain :increment_positions_on_lower_items, :number_assign
      alias_method_chain :increment_positions_on_all_items, :number_assign
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

    def decrement_positions_on_higher_items_with_number_assign
      decrement_positions_on_higher_items_without_number_assign
      self.class.regenerate_numbers(wiki_id, parent_id)
    end

    def decrement_positions_on_lower_items_with_number_assign
      decrement_positions_on_lower_items_without_number_assign
      self.class.regenerate_numbers(wiki_id, parent_id)
    end

    def increment_positions_on_higher_items_with_number_assign
      increment_positions_on_higher_items_without_number_assign
      self.class.regenerate_numbers(wiki_id, parent_id)
    end

    def increment_positions_on_lower_items_with_number_assign
      increment_positions_on_lower_items_without_number_assign
      self.class.regenerate_numbers(wiki_id, parent_id)
    end

    def increment_positions_on_all_items_with_number_assign
      increment_positions_on_all_items_without_number_assign
      self.class.regenerate_numbers(wiki, parent_id)
    end

    module ClassMethods
      def regenerate_numbers(wiki_id, parent_id)
        self.where(:wiki_id => wiki_id, :parent_id => parent_id).each { |p| p.generate_number; p.save }
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

    def update_number
      if parent_id_changed?
        # Can't use decrement_positions_on_lower_items here because parent_id has changed
        self.class.where("wiki_id = ? AND parent_id = ? AND position > ?", wiki_id, parent_id_was, position).update_all("position = position - 1")
        self.class.regenerate_numbers(wiki_id, parent_id_was)
        add_to_list_bottom
        generate_number
      elsif position_changed?
        generate_number
      end
    end
  end
end