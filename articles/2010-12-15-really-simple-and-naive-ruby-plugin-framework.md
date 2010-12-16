title: Really simple and naïve Ruby plugin framework
slug:  really-simple-and-naive-ruby-plugin-framework


I recently found myself writing some Ruby (IronRuby to be specific) at work for
[Umbraco](http://umbraco.org/) that needed to generate HTML for different types of content,
destined to be displayed in an aside column. There are many ways of doing something like this,
but in order to not violate the
[Open-Closed Principle](http://en.wikipedia.org/wiki/Open/closed_principle), I decided to
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
