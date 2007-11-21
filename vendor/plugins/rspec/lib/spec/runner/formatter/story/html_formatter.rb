require 'erb'

module Spec
  module Runner
    module Formatter
      module Story
        class HtmlFormatter < BaseTextFormatter
          include ERB::Util
          
          def run_started(count)
            @output.puts <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html 
  PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Stories</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="Expires" content="-1" />
    <meta http-equiv="Pragma" content="no-cache" />
    <link href="stylesheets/style.css" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <div id="container">
EOF
          end
          def run_ended
            @output.puts <<-EOF
    </div>
  </body>
</head>
EOF
          end
          
          def story_started(title, narrative)
            @output.puts <<-EOF
      <dl class="story passed">
        <dt>#{h title}</dt>
        <dd>
          <p>
            #{h(narrative).split("\n").join("<br />")}
          </p>
EOF
          end

          def story_ended(title, narrative)
            @output.puts <<-EOF
        </dd>
      </dl>
EOF
          end

          def scenario_started(story_title, scenario_name)
            @output.puts <<-EOF
          <dl class="passed">
            <dt>#{h scenario_name}</dt>
            <dd>
              <ul class="steps">
EOF
          end

          def scenario_ended
            @output.puts <<-EOF
              </ul>
            </dd>
          </dl>
EOF
          end
          
          def found_scenario(type, description)
          end

          def scenario_succeeded(story_title, scenario_name)
            scenario_ended
          end

          def scenario_pending(story_title, scenario_name, reason)
            scenario_ended
          end

          def scenario_failed(story_title, scenario_name, err)
            scenario_ended
          end

          def step_succeeded(type, description, *args)
            print_step('passed', type, description, *args) # TODO: uses succeeded CSS class
          end

          def step_pending(type, description, *args)
            print_step('pending', type, description, *args)
          end

          def step_failed(type, description, *args)
            print_step('failed', type, description, *args)
          end
          
          def print_step(klass, type, description, *args)
            inner = h description
            @output.puts "                <li class=\"#{klass}\">#{inner}</li>"
          end

        end
      end
    end
  end
end