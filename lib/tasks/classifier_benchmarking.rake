# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

namespace :winnow do
  desc "Run a series of benchmarks on the classifier"
  task  :classifier_bm do
    RAILS_ENV = ENV['RAILS_ENV'] = 'classifier_benchmarking'
    Rake::Task['environment'].invoke
    ClassifierBenchmarker.new.run   
  end  
  
  task :classifier_prof do
    RAILS_ENV = ENV['RAILS_ENV'] = 'classifier_benchmarking'
    Rake::Task['environment'].invoke
    require 'ruby-prof'
    classifier = User.find(:first).classifier
    options = classifier.classification_options
    classifier.classifier.tokenizer.do_caching = false
    classifier.update_training
    classifier.classify_all(:limit => 2000, :save => false) # rehearsal
    
    result = RubyProf.profile do
      classifier.classify_all(:limit => 2000, :save => false)
    end

    # Print a graph profile to text
    printer = RubyProf::GraphHtmlPrinter.new(result)
    printer.print(File.new('classifier_profile.html', 'w'), 5)    
  end
  
  desc "Benchmark the tokenizer"
  task :token_bm do
    RAILS_ENV = ENV['RAILS_ENV'] = 'classifier_benchmarking'
    Rake::Task['environment'].invoke
    tokenizer = FeedItemTokenizer.new
    FeedItemTokensContainer.delete_all
    
    Benchmark.bm(12) do |x|
      x.report("tokenizing:") do
        Token.with_token_flushing do
          FeedItem.find(:all, :include => :feed_item_content, :limit => ENV['limit']).each do |fi|
            tokenizer.tokens(fi)
          end
        end
      end
    end
    
    puts "Tokens for #{FeedItemTokensContainer.count} items generated"
  end
end

require 'benchmark'
class ClassifierBenchmarker
  def initialize
    @do_db = true
  end
  
  def run
    classifier = User.find(:first).classifier
    options = classifier.classification_options
    membench = {}
    
    membench['BASE'] = memsize()
    
    Benchmark.bm(9) do |x|
      x.report("training:") {classifier.retrain(false)}
    end
    
    membench['TRAINED'] = memsize()
    
    if @do_db
      puts "\nBenchmarks with full database access\n"

      Benchmark.benchmark("Tag    N-items" + Benchmark::CAPTION) do |x|
        [10, 100, 500, 1000, 2000].each do |i|
          %w(1p1n 5p5n 5p10n 10p5n).each do |tag|
            x.report("%-7s %6i" % [tag, i]) { classifier.classify_all(:limit => i, :only => [tag], :save => false) }
            classifier.taggings.delete_all!    
            classifier.classifier.clear_prob_cache      
          end
          x.report("%-7s %6i" % ['ALL', i]) { classifier.classify_all(:limit => i, :save => false) }
          membench['ALLDB'] = memsize() if i == 2000
          classifier.taggings.delete_all!
          classifier.classifier.clear_prob_cache 
        end
      end
    end
    
    # Make sure all tokens are cached in memory for
    items = FeedItem.find(:all, :order => 'time DESC', :limit => 2000)
    items.each do |i|
      classifier.classifier.tokenizer.tokens(i)
    end
    membench['CACHED'] = memsize()
    
    puts "\nBenchmarks without database access\n"
    
    Benchmark.benchmark("Tag    N-items" + Benchmark::CAPTION) do |x|
      [10, 100, 500, 1000, 2000].each do |i|
        %w(1p1n 5p5n 5p10n 10p5n).each do |tag|
          my_options = options.merge(:only => [tag])
          x.report("%-7s %6i" % [tag, i]) do
            items.each_with_index do |item, index|
              classifier.guess(item, my_options)
              break if index >= i
            end
          end
          classifier.classifier.clear_prob_cache 
        end
        x.report("%-7s %6i" % ['ALL', i]) do
          items.each_with_index do |item, index|
            classifier.guess(item, options)
            break if index >= i
          end
        end
        membench['ALLNDB'] = memsize() if i == 2000
        classifier.classifier.clear_prob_cache 
      end
    end    

    puts "\nMemory Benchmarks\n"
    puts "%-7s %10s %10s %10s %10s %10s %10s" % ['', 'n-objects', 'num_strs', 'size_strs', 'num_numerics', 'size(MB)', 'RSS(MB)']
    puts ("%-7s %10i %10i %10i %10i %10i %10i" % (['BASE'] + membench.delete('BASE')))
    puts ("%-7s %10i %10i %10i %10i %10i %10i" % (['TRAINED'] + membench.delete('TRAINED')))
    puts ("%-7s %10i %10i %10i %10i %10i %10i" % (['CACHED'] + membench.delete('CACHED')))
    puts ("%-7s %10i %10i %10i %10i %10i %10i" % (['ALLNDB'] + membench.delete('ALLNDB')))
    puts ("%-7s %10i %10i %10i %10i %10i %10i" % (['ALLDB'] + membench.delete('ALLDB'))) if @do_db
  end
  
  def memsize
    GC.start
    num_str = 0
    str_size = 0
    num_numerics = 0
    nobjects = 0
    size = 0
    ObjectSpace.each_object do |o|
      nobjects += 1
      size += Marshal.dump(o).size rescue 0
      if o.is_a?(String)
        num_str += 1
        str_size += o.size
      elsif o.is_a?(Numeric)
        num_numerics += 1
      end
    end
    [nobjects, num_str, str_size / 1024 /1024, num_numerics, size / 1024 / 1024, `ps -orss -p #{Process.pid}`.sub('RSS','').to_i / 1024]
  end
end