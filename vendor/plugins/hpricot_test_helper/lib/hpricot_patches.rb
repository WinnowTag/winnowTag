class Hpricot::Elem
  def should_contain(value)
    self.inner_text.include?(value)
  end
  
  # courtesy of 'thomas' from the comments
  # of _whys blog - get in touch if you want a better credit!
  def inner_text
    self.children.collect do |child|
      child.is_a?(Hpricot::Text) ? child.content : child.inner_text
    end.join.strip
  end
end