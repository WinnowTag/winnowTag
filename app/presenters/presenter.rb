class Presenter
  attr_accessor :current_user

  def initialize(options = {})
    options.each do |key, value|
      send "#{key}=", value
    end
  end
end