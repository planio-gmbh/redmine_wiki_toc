module RedmineWikiToc
  module WikiPagePatch
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
      base.class_eval do
        before_create :add_to_list_bottom
        before_create :assign_number
        before_update :assign_number, :if => lambda { |p| p.position_changed? || p.number_delta_changed? }
        before_destroy :remove_from_list

        before_update :if => :parent_id_changed? do |p|
          WikiPage.old_branch(self).find(:all, :conditions => ["position > ?", position]).each do |page|
            page.adjust_position(-1)
          end
          p.add_to_list_bottom
          p.parent.try(:reload)
          p.assign_number
        end

        before_update :if => :number_enabled_changed? do |p|
          p.adjust_positions_on_lower_items(0, p.number_enabled? ? 1 : -1)
          p.assign_number_delta if p.number_enabled?
          p.assign_number
        end

        after_update :if => lambda { |p| p.changed.include?('number') } do |p|
          p.children.find(:all, :include => :parent).each do |t|
            t.assign_number
            t.save_without_validation
          end
        end

        alias_method_chain :pretty_title, :number

        class_attribute :numeric_prefix_disabled_tmp

        safe_attributes 'number_enabled'
        safe_attributes 'position', 'move_to',
          :if => lambda { |page, user| page.new_record? || user.allowed_to?(:reorder_wiki_pages, page.project, :object => page) }

        if Rails::VERSION::MAJOR >= 3
          scope :branch, lambda { |page|
            where(:parent_id => page.parent_id, :wiki_id => page.wiki_id)
          }

          scope :old_branch, lambda { |page|
            where(:parent_id => page.parent_id_was, :wiki_id => page.wiki_id_was)
          }
        else
          named_scope :branch, lambda { |page|
            { :conditions => {:parent_id => page.parent_id, :wiki_id => page.wiki_id} }
          }
          named_scope :old_branch, lambda { |page|
            { :conditions => {:parent_id => page.parent_id_was, :wiki_id => page.wiki_id_was} }
          }
        end
      end
    end

    module InstanceMethods
      def <=>(other)
        self.position <=> other.position
      end

      def number_delta
        has_attribute?(:number_delta) ? read_attribute('number_delta') : 0
      end

      def number_enabled?
        has_attribute?(:number_enabled) ? read_attribute('number_enabled') : true
      end

      def number_delta_changed?
        has_attribute?(:number_delta) ? attribute_changed?('number_delta') : false
      end

      def number_enabled_changed?
        has_attribute?(:number_enabled) ? attribute_changed?('number_enabled') : false
      end

      def numeric_prefix
        !numeric_prefix_disabled? && number.present? ? number+". " : ""
      end

      def numeric_prefix_disabled?
        self.class.numeric_prefix_disabled_tmp? || !project.module_enabled?(:wiki_toc) || !number_enabled?
      end

      def pretty_title_with_number
        numeric_prefix + pretty_title_without_number
      end

      # Swap positions with the next lower item, if one exists.
      def move_lower
        return unless lower_item
        self.class.transaction do
          lower_item.adjust_position(-1, !number_enabled? ? 1 : 0)
          adjust_position(1, !lower_item.number_enabled? ? -1 : 0)
        end
      end

      # Swap positions with the next higher item, if one exists.
      def move_higher
        return unless higher_item
        self.class.transaction do
          higher_item.adjust_position(1, !number_enabled? ? -1 : 0)
          adjust_position(-1, !higher_item.number_enabled? ? 1 : 0)
        end
      end

      # Move to the bottom of the list. If the item is already in the list, the items below it have their
      # position adjusted accordingly.
      def move_to_bottom
        return unless in_list?
        self.class.transaction do
          adjust_positions_on_lower_items(-1, !number_enabled? ? 1 : 0)
          assume_bottom_position
        end
      end

      # Move to the top of the list. If the item is already in the list, the items above it have their
      # position adjusted accordingly.
      def move_to_top
        return unless in_list?
        self.class.transaction do
          adjust_positions_on_higher_items(1, !number_enabled? ? -1 : 0)
          assume_top_position
        end
      end

      # Move to the given position
      def move_to=(pos)
        case pos.to_s
        when 'highest'
          move_to_top
        when 'higher'
          move_higher
        when 'lower'
          move_lower
        when 'lowest'
          move_to_bottom
        end
      end

      def in_list?
        position
      end

      # Removes the item from the list.
      def remove_from_list
        if in_list?
          adjust_positions_on_lower_items(-1)
          self.position = nil
          save_without_validation
        end
      end

      # Adjust the position of this item without adjusting the rest of the list.
      def adjust_position(position_delta, number_delta_delta = 0)
        return unless in_list?
        self.position = position + position_delta
        self.number_delta = number_delta + number_delta_delta
        save_without_validation
      end

      # Return +true+ if this object is the first in the list.
      def first?
        return false unless in_list?
        position == 1
      end

      # Return +true+ if this object is the last in the list.
      def last?
        return false unless in_list?
        position == bottom_position_in_list
      end

      # Return the next higher item in the list.
      def higher_item
        return nil unless in_list?
        @higher_item ||= self.class.branch(self).find(:first, :conditions => {:position => position-1})
      end

      # Return the next lower item in the list.
      def lower_item
        return nil unless in_list?
        @lower_item ||= self.class.branch(self).find(:first, :conditions => {:position => position+1})
      end

      def add_to_list_bottom
        self.position = bottom_position_in_list + 1
        assign_number_delta
      end

      # Returns the bottom position number in the list.
      #   bottom_position_in_list    # => 2
      def bottom_position_in_list(except = nil)
        item = bottom_item(except)
        item ? item.position : 0
      end

      def assign_number_delta
        self.number_delta = -self.class.branch(self).count(:conditions => ["number_enabled=? AND position<?", false, position])
      end

      # Returns the bottom item
      def bottom_item(except = nil)
        conditions = except ? ["id != ?", except.id] : []
        self.class.branch(self).find(:first, :conditions => conditions, :order => "position DESC")
      end

      # Forces item to assume the bottom position in the list.
      def assume_bottom_position
        self.position = bottom_position_in_list(self) + 1
        assign_number_delta
        save_without_validation
      end

      # Forces item to assume the top position in the list.
      def assume_top_position
        self.position = 1
        assign_number_delta
        save_without_validation
      end

      # This has the effect of moving all the lower items up one.
      def adjust_positions_on_lower_items(position_delta, number_delta_delta = 0)
        self.class.transaction do
          self.class.branch(self).find(:all, :conditions => ["position > ?", position]).each do |page|
            page.adjust_position(position_delta, number_delta_delta)
          end
        end
      end

      # This has the effect of moving all the higher items down one.
      def adjust_positions_on_higher_items(position_delta, number_delta_delta = 0)
        self.class.transaction do
          self.class.branch(self).find(:all, :conditions => ["position < ?", position]).each do |page|
            page.adjust_position(position_delta, number_delta_delta)
          end
        end
      end

      def assign_number
        return unless in_list?
        self.number = number_enabled? ? (parent && parent.number.present? && parent.number+"." || "") + (position+number_delta).to_s : ""
      end

      def save_without_validation
        defined?(super) ? super : save(:validate => false)
      end
    end

    module ClassMethods
      def with_disabled_numeric_prefix
        self.numeric_prefix_disabled_tmp = true
        result = yield
        self.numeric_prefix_disabled_tmp = false
        result
      end
    end
  end
end