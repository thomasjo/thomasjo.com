title: Really simple and naïve Ruby plugin framework
slug:  really-simple-and-naive-ruby-plugin-framework


I recently found myself writing some Ruby (IronRuby to be specific) at work for
[Umbraco](http://umbraco.org/) that needed to generate HTML for different types of content,
destined to be displayed in an aside column. There are many ways of doing something like this,
but in order to not violate the
[Open/Closed Principle](http://en.wikipedia.org/wiki/Open/closed_principle), I decided to
create a very simple and naïve plugin framework that would automagically wire up new
content-type handlers.
The way I chose to implement this, was to leverage the meta-programming capabilities in Ruby,
more specifically the `implemented` hook.~

### Say hello to your friendly neighbourhood hooks
One of the most powerful aspects of Ruby, is its meta-programming capabilities; the aspect that
allows you to shape the language to fit your needs and requirements - at runtime.

Hooks are perhaps not strictly speaking a meta-programming capability, but they play a very
important role in meta-programming. Undoubtedly the most infamous of all the hooks is
`method_missing`. As the name suggest, it's the hook that allows you to intercept calls to
undefined methods.

    class Hello
      def method_missing(name, *args)
        "Hello #{name.capitalize}!"
      end
    end

    hello = Hello.new
    puts hello.neighbour  # "Hello Neighbour!"

### Respect the hook
To implement the plugin framework, I decided to leverage a seemingly under-appreciated hook
found on `Class` called `implemented`. Yet again, the name gives it all away - this hook is
called whenever the class is implemented (sub-classed.) We can utilise this hook to implement a
simple plugin registration system packaged up in a module.

    module Plugin
      module ClassMethods
        def repository
          @repository ||= []
        end

        def inherited(klass)
          repository << klass
        end
      end
  
      def self.included(klass)
        klass.extend ClassMethods  # Somewhat controversial
      end
    end

Because we want to add singleton methods to whatever class includes our plugin module, we use
a common, albeit slightly controversial technique; leverage another hook - `#included` - to
automagically extend the target class with the our `ClassMethods` modules.

### Let's build some plugins!
With the `Plugin` module we have the foundation needed to implement various types of plugins;
let's create a very silly plugin type for displaying various kinds of messages.

    # ./lib/message_plugin.rb
    require './lib/plugin'

    class MessagePlugin
      include Plugin
  
      def display_output
        raise NotImplementedError.new('OH NOES!')
      end
    end
    
    # ./plugins/hello_world.rb
    class HelloWorld < MessagePlugin
      def display_output
        puts 'Hello World! :-)'
      end
    end
    
    # ./plugins/goodbye_world.rb
    class GoodbyeWorld < MessagePlugin
      def display_output
        puts 'Goodbye World... :-('
      end
    end

Because we've taken advantage of the `inherited` hook, all that is necessary for plugins of
type `MessagePlugin` to work, is to require the files containing the implementations, e.g.
a directory called "plugins."

    dir = './plugins'
    $LOAD_PATH.unshift(dir)
    Dir[File.join(dir, '*.rb')].each {|file| require File.basename(file) }

Now all that is required for someone to add a new message to our application, is to inherit
from `MessagePlugin` and drop the implementation into the "plugins" folder.

### Taking it one step further...
The `MessagePlugin` is extremely simple - what if we want to pass data to a plugin? Perhaps we
only want to pass the data to plugins that can handle that type of data. An easy way
of pulling this off, is to query the registered plugins on whether they can handle it.

    # ./lib/type_handler_plugin.rb
    require './lib/plugin'

    class TypeHandlerPlugin
      include Plugin

      def self.for_type(type)
        repository.find {|handler| handler.can_handle? type }
      end
    end

    # ./plugins/string_handler.rb
    class StringHandler < TypeHandlerPlugin
      def self.can_handle?(type)
        type == String
      end

      def display_output(data)
        puts "String: #{data}"
      end
    end
    
    # ./plugins/time_handler.rb
    class TimeHandler < TypeHandlerPlugin
      def self.can_handle?(type)
        type == Time
      end

      def display_output(data)
        puts "Formatted Time: #{data.strftime '%A, %B %m, %Y'}"
      end
    end
    
The `#can_handle?(type)` predicate method hands the responsibility over to the plugins, thus
requiring no changes to any other class whenever we add a new type and/or type handler to the
application. The Open/Closed Principle remains unviolated.

### One more thing...
Just for good measure, here is a rather silly test harness for running the various plugins
we've peeked at - enjoy responsibly!

    require './lib/array'
    require './lib/message_plugin'
    require './lib/type_handler_plugin'

    #
    # Add plugins folder to LOAD_PATH and subsequently require all plugins.
    #
    dir = './plugins'
    $LOAD_PATH.unshift(dir)
    Dir[File.join(dir, '*.rb')].each {|file| require File.basename(file) }

    class TestHarness
      def self.run
        run_message_plugin
        run_type_handler_plugin
      end

      private

        def self.run_message_plugin
          message_plugin = MessagePlugin.repository.random.new
          message_plugin.display_output
        end

        def self.run_type_handler_plugin
          random_data = [Time.now, 'Example string.', 1337].random
          type_handler_plugin = TypeHandlerPlugin.for_type(random_data.class)
          unless type_handler_plugin.nil?
            type_handler_plugin = type_handler_plugin.new 
            type_handler_plugin.display_output(random_data)
          end
        end
    end

    TestHarness.run

