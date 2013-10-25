class JPathTree
  attr_accessor :jpath, :tree

  def initialize(jpath)
    self.jpath = jpath
    self.tree = (jpath.nil? or jpath.empty? or !jpath.match(/^\//)) ? nil : {}
    self.tree || return

    prev_key = nil
    self.jpath.split('/')[1..-1].each do |name|
      name = name.intern
      self.tree[name] = {prev: prev_key, value: false, next: nil}
      self.tree[prev_key][:next] = name if prev_key
      prev_key = name
    end
  end

  def parsing_feasible?(key)
    key = key.is_a?(String) ? key.intern : nil
    return if key.nil? or self.tree.nil? or self.tree.empty?

    node = self.tree[key]

    return unless (node)
    return if (node[:value])

    prev_node = self.tree[node[:prev]]
    next_node = self.tree[node[:next]]

    if (next_node.nil?)
      if (prev_node.nil? || prev_node[:value])
        node[:value] = true
        return true
      end
    elsif (prev_node.nil? || prev_node[:value])
      node[:value] = true
      return nil
    else
      return nil
    end
  end

end

