module RedmineWikiToc
  module WikiPagePatch
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
      base.class_eval do
        acts_as_list :scope => 'parent_id #{parent_id ? "= #{parent_id}" : "IS NULL"} AND wiki_id = #{wiki_id}'

        before_create :assign_number
        before_update :assign_number_if_parent_id_changed

        before_update do |page|
          page.assign_number if page.position_changed?
        end

        after_update do |page|
          if page.changed.include?("number")
            page.children.find(:all, :include => :parent).each do |t|
              t.assign_number
              t.save
            end
          end
        end

        alias_method_chain :pretty_title, :number
        class_attribute :number_prefix_disabled_tmp

        safe_attributes 'position', 'move_to',
          :if => lambda { |page, user| page.new_record? || user.allowed_to?(:reorder_wiki_pages, page.project, :object => page) }

        alias_method_chain :decrement_positions_on_higher_items, :number_assign
        alias_method_chain :decrement_positions_on_lower_items, :number_assign
        alias_method_chain :increment_positions_on_higher_items, :number_assign
        alias_method_chain :increment_positions_on_lower_items, :number_assign
        alias_method_chain :increment_positions_on_all_items, :number_assign
      end
    end

    module InstanceMethods
      def <=>(other)
        self.position <=> other.position
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
        self.class.assign_numbers(wiki_id, parent_id)
      end

      def decrement_positions_on_lower_items_with_number_assign
        decrement_positions_on_lower_items_without_number_assign
        self.class.assign_numbers(wiki_id, parent_id)
      end

      def increment_positions_on_higher_items_with_number_assign
        increment_positions_on_higher_items_without_number_assign
        self.class.assign_numbers(wiki_id, parent_id)
      end

      def increment_positions_on_lower_items_with_number_assign
        increment_positions_on_lower_items_without_number_assign
        self.class.assign_numbers(wiki_id, parent_id)
      end

      def increment_positions_on_all_items_with_number_assign
        increment_positions_on_all_items_without_number_assign
        self.class.assign_numbers(wiki, parent_id)
      end

      def assign_number
        self.number = (parent && parent.number.present? && parent.number+"." || "") + position.to_s
      end

      def assign_number_if_parent_id_changed
        return unless parent_id_changed?
        # Can't use decrement_positions_on_lower_items here because parent_id has changed
        scope = WikiPage.scoped(:conditions => {:wiki_id => wiki_id, :parent_id => parent_id_was})
        scope.update_all("position = position - 1", ["position > ?", position])
        WikiPage.assign_numbers(wiki_id, parent_id_was)
        add_to_list_bottom
        parent.try(:reload)
        assign_number
      end
    end

    module ClassMethods
      def assign_numbers(wiki_id, parent_id)
        self.find(:all, :conditions => {:wiki_id => wiki_id, :parent_id => parent_id}).each do |page|
          page.assign_number
          page.save
        end
      end

      def with_disabled_number_prefix
        self.number_prefix_disabled_tmp = true
        result = yield
        self.number_prefix_disabled_tmp = false
        result
      end
    end
  end
end