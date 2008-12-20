require 'spec'
$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'calculadora'

Before do
  @calc = Calculadora.new
end

After do
end

Given /que eu digitei (\d+) na calculadora/ do |n|
  @calc.push n.to_i
end

When 'eu aperto o botão de soma' do
  @result = @calc.soma
end

Then /o resultado na calculadora deve ser (\d*)/ do |result|
  @result.should == result.to_i
end
