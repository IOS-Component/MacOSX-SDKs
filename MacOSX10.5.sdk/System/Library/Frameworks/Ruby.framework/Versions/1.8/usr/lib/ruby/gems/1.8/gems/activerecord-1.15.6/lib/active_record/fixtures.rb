require 'erb'
require 'yaml'
require 'csv'

module YAML #:nodoc:
  class Omap #:nodoc:
    def keys;   map { |k, v| k } end
    def values; map { |k, v| v } end
  end
end

class FixtureClassNotFound < ActiveRecord::ActiveRecordError #:nodoc:
end

# Fixtures are a way of organizing data that you want to test against; in short, sample data. They come in 3 flavours:
#
#   1.  YAML fixtures
#   2.  CSV fixtures
#   3.  Single-file fixtures
#
# = YAML fixtures
#
# This type of fixture is in YAML format and the preferred default. YAML is a file format which describes data structures
# in a non-verbose, humanly-readable format. It ships with Ruby 1.8.1+.
#
# Unlike single-file fixtures, YAML fixtures are stored in a single file per model, which are placed in the directory appointed
# by <tt>Test::Unit::TestCase.fixture_path=(path)</tt> (this is automatically configured for Rails, so you can just
# put your files in <your-rails-app>/test/fixtures/). The fixture file ends with the .yml file extension (Rails example:
# "<your-rails-app>/test/fixtures/web_sites.yml"). The format of a YAML fixture file looks like this:
#
#   rubyonrails:
#     id: 1
#     name: Ruby on Rails
#     url: http://www.rubyonrails.org
#
#   google:
#     id: 2
#     name: Google
#     url: http://www.google.com
#
# This YAML fixture file includes two fixtures.  Each YAML fixture (ie. record) is given a name and is followed by an
# indented list of key/value pairs in the "key: value" format.  Records are separated by a blank line for your viewing
# pleasure.
#
# Note that YAML fixtures are unordered. If you want ordered fixtures, use the omap YAML type.  See http://yaml.org/type/omap.html
# for the specification.  You will need ordered fixtures when you have foreign key constraints on keys in the same table.
# This is commonly needed for tree structures.  Example:
#
#    --- !omap
#    - parent:
#        id:         1
#        parent_id:  NULL
#        title:      Parent
#    - child:
#        id:         2
#        parent_id:  1
#        title:      Child
#
# = CSV fixtures
#
# Fixtures can also be kept in the Comma Separated Value format. Akin to YAML fixtures, CSV fixtures are stored
# in a single file, but instead end with the .csv file extension (Rails example: "<your-rails-app>/test/fixtures/web_sites.csv")
#
# The format of this type of fixture file is much more compact than the others, but also a little harder to read by us
# humans.  The first line of the CSV file is a comma-separated list of field names.  The rest of the file is then comprised
# of the actual data (1 per line).  Here's an example:
#
#   id, name, url
#   1, Ruby On Rails, http://www.rubyonrails.org
#   2, Google, http://www.google.com
#
# Should you have a piece of data with a comma character in it, you can place double quotes around that value.  If you
# need to use a double quote character, you must escape it with another double quote.
#
# Another unique attribute of the CSV fixture is that it has *no* fixture name like the other two formats.  Instead, the
# fixture names are automatically generated by deriving the class name of the fixture file and adding an incrementing
# number to the end.  In our example, the 1st fixture would be called "web_site_1" and the 2nd one would be called
# "web_site_2".
#
# Most databases and spreadsheets support exporting to CSV format, so this is a great format for you to choose if you
# have existing data somewhere already.
#
# = Single-file fixtures
#
# This type of fixtures was the original format for Active Record that has since been deprecated in favor of the YAML and CSV formats.
# Fixtures for this format are created by placing text files in a sub-directory (with the name of the model) to the directory
# appointed by <tt>Test::Unit::TestCase.fixture_path=(path)</tt> (this is automatically configured for Rails, so you can just
# put your files in <your-rails-app>/test/fixtures/<your-model-name>/ -- like <your-rails-app>/test/fixtures/web_sites/ for the WebSite
# model).
#
# Each text file placed in this directory represents a "record".  Usually these types of fixtures are named without
# extensions, but if you are on a Windows machine, you might consider adding .txt as the extension.  Here's what the
# above example might look like:
#
#   web_sites/google
#   web_sites/yahoo.txt
#   web_sites/ruby-on-rails
#
# The file format of a standard fixture is simple.  Each line is a property (or column in db speak) and has the syntax
# of "name => value".  Here's an example of the ruby-on-rails fixture above:
#
#   id => 1
#   name => Ruby on Rails
#   url => http://www.rubyonrails.org
#
# = Using Fixtures
#
# Since fixtures are a testing construct, we use them in our unit and functional tests.  There are two ways to use the
# fixtures, but first let's take a look at a sample unit test found:
#
#   require 'web_site'
#
#   class WebSiteTest < Test::Unit::TestCase
#     def test_web_site_count
#       assert_equal 2, WebSite.count
#     end
#   end
#
# As it stands, unless we pre-load the web_site table in our database with two records, this test will fail.  Here's the
# easiest way to add fixtures to the database:
#
#   ...
#   class WebSiteTest < Test::Unit::TestCase
#     fixtures :web_sites # add more by separating the symbols with commas
#   ...
#
# By adding a "fixtures" method to the test case and passing it a list of symbols (only one is shown here tho), we trigger
# the testing environment to automatically load the appropriate fixtures into the database before each test.  
# To ensure consistent data, the environment deletes the fixtures before running the load.
#
# In addition to being available in the database, the fixtures are also loaded into a hash stored in an instance variable
# of the test case.  It is named after the symbol... so, in our example, there would be a hash available called
# @web_sites.  This is where the "fixture name" comes into play.
#
# On top of that, each record is automatically "found" (using Model.find(id)) and placed in the instance variable of its name.
# So for the YAML fixtures, we'd get @rubyonrails and @google, which could be interrogated using regular Active Record semantics:
#
#   # test if the object created from the fixture data has the same attributes as the data itself
#   def test_find
#     assert_equal @web_sites["rubyonrails"]["name"], @rubyonrails.name
#   end
#
# As seen above, the data hash created from the YAML fixtures would have @web_sites["rubyonrails"]["url"] return
# "http://www.rubyonrails.org" and @web_sites["google"]["name"] would return "Google". The same fixtures, but loaded
# from a CSV fixture file, would be accessible via @web_sites["web_site_1"]["name"] == "Ruby on Rails" and have the individual
# fixtures available as instance variables @web_site_1 and @web_site_2.
#
# If you do not wish to use instantiated fixtures (usually for performance reasons) there are two options.
#
#   - to completely disable instantiated fixtures:
#       self.use_instantiated_fixtures = false
#
#   - to keep the fixture instance (@web_sites) available, but do not automatically 'find' each instance:
#       self.use_instantiated_fixtures = :no_instances 
#
# Even if auto-instantiated fixtures are disabled, you can still access them
# by name via special dynamic methods. Each method has the same name as the
# model, and accepts the name of the fixture to instantiate:
#
#   fixtures :web_sites
#
#   def test_find
#     assert_equal "Ruby on Rails", web_sites(:rubyonrails).name
#   end
#
# = Dynamic fixtures with ERb
#
# Some times you don't care about the content of the fixtures as much as you care about the volume. In these cases, you can
# mix ERb in with your YAML or CSV fixtures to create a bunch of fixtures for load testing, like:
#
# <% for i in 1..1000 %>
# fix_<%= i %>:
#   id: <%= i %>
#   name: guy_<%= 1 %>
# <% end %>
#
# This will create 1000 very simple YAML fixtures.
#
# Using ERb, you can also inject dynamic values into your fixtures with inserts like <%= Date.today.strftime("%Y-%m-%d") %>.
# This is however a feature to be used with some caution. The point of fixtures are that they're stable units of predictable
# sample data. If you feel that you need to inject dynamic values, then perhaps you should reexamine whether your application
# is properly testable. Hence, dynamic values in fixtures are to be considered a code smell.
#
# = Transactional fixtures
#
# TestCases can use begin+rollback to isolate their changes to the database instead of having to delete+insert for every test case. 
# They can also turn off auto-instantiation of fixture data since the feature is costly and often unused.
#
#   class FooTest < Test::Unit::TestCase
#     self.use_transactional_fixtures = true
#     self.use_instantiated_fixtures = false
#   
#     fixtures :foos
#   
#     def test_godzilla
#       assert !Foo.find(:all).empty?
#       Foo.destroy_all
#       assert Foo.find(:all).empty?
#     end
#   
#     def test_godzilla_aftermath
#       assert !Foo.find(:all).empty?
#     end
#   end
#   
# If you preload your test database with all fixture data (probably in the Rakefile task) and use transactional fixtures, 
# then you may omit all fixtures declarations in your test cases since all the data's already there and every case rolls back its changes.
#
# In order to use instantiated fixtures with preloaded data, set +self.pre_loaded_fixtures+ to true. This will provide 
# access to fixture data for every table that has been loaded through fixtures (depending on the value of +use_instantiated_fixtures+)
#
# When *not* to use transactional fixtures: 
#   1. You're testing whether a transaction works correctly. Nested transactions don't commit until all parent transactions commit, 
#      particularly, the fixtures transaction which is begun in setup and rolled back in teardown. Thus, you won't be able to verify 
#      the results of your transaction until Active Record supports nested transactions or savepoints (in progress.) 
#   2. Your database does not support transactions. Every Active Record database supports transactions except MySQL MyISAM. 
#      Use InnoDB, MaxDB, or NDB instead.
class Fixtures < YAML::Omap
  DEFAULT_FILTER_RE = /\.ya?ml$/

  def self.instantiate_fixtures(object, table_name, fixtures, load_instances=true)
    object.instance_variable_set "@#{table_name.to_s.gsub('.','_')}", fixtures
    if load_instances
      ActiveRecord::Base.silence do
        fixtures.each do |name, fixture|
          begin
            object.instance_variable_set "@#{name}", fixture.find
          rescue FixtureClassNotFound
            nil
          end
        end
      end
    end
  end

  def self.instantiate_all_loaded_fixtures(object, load_instances=true)
    all_loaded_fixtures.each do |table_name, fixtures|
      Fixtures.instantiate_fixtures(object, table_name, fixtures, load_instances)
    end
  end
  
  cattr_accessor :all_loaded_fixtures
  self.all_loaded_fixtures = {}

  def self.create_fixtures(fixtures_directory, table_names, class_names = {})
    table_names = [table_names].flatten.map { |n| n.to_s }
    connection = block_given? ? yield : ActiveRecord::Base.connection
    ActiveRecord::Base.silence do
      fixtures_map = {}
      fixtures = table_names.map do |table_name|
        fixtures_map[table_name] = Fixtures.new(connection, File.split(table_name.to_s).last, class_names[table_name.to_sym], File.join(fixtures_directory, table_name.to_s))
      end               
      all_loaded_fixtures.merge! fixtures_map  

      connection.transaction(Thread.current['open_transactions'] == 0) do
        fixtures.reverse.each { |fixture| fixture.delete_existing_fixtures }
        fixtures.each { |fixture| fixture.insert_fixtures }

        # Cap primary key sequences to max(pk).
        if connection.respond_to?(:reset_pk_sequence!)
          table_names.each do |table_name|
            connection.reset_pk_sequence!(table_name)
          end
        end
      end

      return fixtures.size > 1 ? fixtures : fixtures.first
    end
  end


  attr_reader :table_name

  def initialize(connection, table_name, class_name, fixture_path, file_filter = DEFAULT_FILTER_RE)
    @connection, @table_name, @fixture_path, @file_filter = connection, table_name, fixture_path, file_filter
    @class_name = class_name || 
                  (ActiveRecord::Base.pluralize_table_names ? @table_name.singularize.camelize : @table_name.camelize)
    @table_name = ActiveRecord::Base.table_name_prefix + @table_name + ActiveRecord::Base.table_name_suffix
    @table_name = class_name.table_name if class_name.respond_to?(:table_name)
    @connection = class_name.connection if class_name.respond_to?(:connection)
    read_fixture_files
  end

  def delete_existing_fixtures
    @connection.delete "DELETE FROM #{@table_name}", 'Fixture Delete'
  end

  def insert_fixtures
    values.each do |fixture|
      @connection.execute "INSERT INTO #{@table_name} (#{fixture.key_list}) VALUES (#{fixture.value_list})", 'Fixture Insert'
    end
  end

  private

    def read_fixture_files
      if File.file?(yaml_file_path)
        # YAML fixtures
        yaml_string = ""
        Dir["#{@fixture_path}/**/*.yml"].select {|f| test(?f,f) }.each do |subfixture_path|
          yaml_string << IO.read(subfixture_path)
        end
        yaml_string << IO.read(yaml_file_path)

        begin
          yaml = YAML::load(erb_render(yaml_string))
        rescue Exception=>boom
          raise Fixture::FormatError, "a YAML error occurred parsing #{yaml_file_path}. Please note that YAML must be consistently indented using spaces. Tabs are not allowed. Please have a look at http://www.yaml.org/faq.html\nThe exact error was:\n  #{boom.class}: #{boom}"
        end

        if yaml
          # If the file is an ordered map, extract its children.
          yaml_value =
            if yaml.respond_to?(:type_id) && yaml.respond_to?(:value)
              yaml.value
            else
              [yaml]
            end

          yaml_value.each do |fixture|
            fixture.each do |name, data|
              unless data
                raise Fixture::FormatError, "Bad data for #{@class_name} fixture named #{name} (nil)"
              end

              self[name] = Fixture.new(data, @class_name)
            end
          end
        end
      elsif File.file?(csv_file_path)
        # CSV fixtures
        reader = CSV::Reader.create(erb_render(IO.read(csv_file_path)))
        header = reader.shift
        i = 0
        reader.each do |row|
          data = {}
          row.each_with_index { |cell, j| data[header[j].to_s.strip] = cell.to_s.strip }
          self["#{Inflector::underscore(@class_name)}_#{i+=1}"]= Fixture.new(data, @class_name)
        end
      elsif File.file?(deprecated_yaml_file_path)
        raise Fixture::FormatError, ".yml extension required: rename #{deprecated_yaml_file_path} to #{yaml_file_path}"
      else
        # Standard fixtures
        Dir.entries(@fixture_path).each do |file|
          path = File.join(@fixture_path, file)
          if File.file?(path) and file !~ @file_filter
            self[file] = Fixture.new(path, @class_name)
          end
        end
      end
    end

    def yaml_file_path
      "#{@fixture_path}.yml"
    end

    def deprecated_yaml_file_path
      "#{@fixture_path}.yaml"
    end

    def csv_file_path
      @fixture_path + ".csv"
    end

    def yaml_fixtures_key(path)
      File.basename(@fixture_path).split(".").first
    end

    def erb_render(fixture_content)
      ERB.new(fixture_content).result
    end
end

class Fixture #:nodoc:
  include Enumerable
  class FixtureError < StandardError#:nodoc:
  end
  class FormatError < FixtureError#:nodoc:
  end

  def initialize(fixture, class_name)
    case fixture
      when Hash, YAML::Omap
        @fixture = fixture
      when String
        @fixture = read_fixture_file(fixture)
      else
        raise ArgumentError, "Bad fixture argument #{fixture.inspect} during creation of #{class_name} fixture"
    end

    @class_name = class_name
  end

  def each
    @fixture.each { |item| yield item }
  end

  def [](key)
    @fixture[key]
  end

  def to_hash
    @fixture
  end

  def key_list
    columns = @fixture.keys.collect{ |column_name| ActiveRecord::Base.connection.quote_column_name(column_name) }
    columns.join(", ")
  end

  def value_list
    klass = @class_name.constantize rescue nil

    list = @fixture.inject([]) do |fixtures, (key, value)|
      col = klass.columns_hash[key] if klass.respond_to?(:ancestors) && klass.ancestors.include?(ActiveRecord::Base)
      fixtures << ActiveRecord::Base.connection.quote(value, col).gsub('[^\]\\n', "\n").gsub('[^\]\\r', "\r")
    end
    list * ', '
  end

  def find
    klass = @class_name.is_a?(Class) ? @class_name : Object.const_get(@class_name) rescue nil
    if klass
      klass.find(self[klass.primary_key])
    else
      raise FixtureClassNotFound, "The class #{@class_name.inspect} was not found."
    end
  end

  private
    def read_fixture_file(fixture_file_path)
      IO.readlines(fixture_file_path).inject({}) do |fixture, line|
        # Mercifully skip empty lines.
        next if line =~ /^\s*$/

        # Use the same regular expression for attributes as Active Record.
        unless md = /^\s*([a-zA-Z][-_\w]*)\s*=>\s*(.+)\s*$/.match(line)
          raise FormatError, "#{fixture_file_path}: fixture format error at '#{line}'.  Expecting 'key => value'."
        end
        key, value = md.captures

        # Disallow duplicate keys to catch typos.
        raise FormatError, "#{fixture_file_path}: duplicate '#{key}' in fixture." if fixture[key]
        fixture[key] = value.strip
        fixture
      end
    end
end

module Test #:nodoc:
  module Unit #:nodoc:
    class TestCase #:nodoc:
      cattr_accessor :fixture_path
      class_inheritable_accessor :fixture_table_names
      class_inheritable_accessor :fixture_class_names
      class_inheritable_accessor :use_transactional_fixtures
      class_inheritable_accessor :use_instantiated_fixtures   # true, false, or :no_instances
      class_inheritable_accessor :pre_loaded_fixtures

      self.fixture_table_names = []
      self.use_transactional_fixtures = false
      self.use_instantiated_fixtures = true
      self.pre_loaded_fixtures = false
      
      self.fixture_class_names = {}
      
      @@already_loaded_fixtures = {}
      self.fixture_class_names = {}
      
      def self.set_fixture_class(class_names = {})
        self.fixture_class_names = self.fixture_class_names.merge(class_names)
      end
      
      def self.fixtures(*table_names)
        table_names = table_names.flatten.map { |n| n.to_s }
        self.fixture_table_names |= table_names
        require_fixture_classes(table_names)
        setup_fixture_accessors(table_names)
      end

      def self.require_fixture_classes(table_names=nil)
        (table_names || fixture_table_names).each do |table_name| 
          file_name = table_name.to_s
          file_name = file_name.singularize if ActiveRecord::Base.pluralize_table_names
          begin
            require_dependency file_name
          rescue LoadError
            # Let's hope the developer has included it himself
          end
        end
      end

      def self.setup_fixture_accessors(table_names=nil)
        (table_names || fixture_table_names).each do |table_name|
          table_name = table_name.to_s.tr('.','_')
          define_method(table_name) do |fixture, *optionals|
            force_reload = optionals.shift
            @fixture_cache[table_name] ||= Hash.new
            @fixture_cache[table_name][fixture] = nil if force_reload
            if @loaded_fixtures[table_name][fixture.to_s]
              @fixture_cache[table_name][fixture] ||= @loaded_fixtures[table_name][fixture.to_s].find
            else
              raise StandardError, "No fixture with name '#{fixture}' found for table '#{table_name}'"
            end
          end
        end
      end

      def self.uses_transaction(*methods)
        @uses_transaction = [] unless defined?(@uses_transaction)
        @uses_transaction.concat methods.map(&:to_s)
      end

      def self.uses_transaction?(method)
        @uses_transaction = [] unless defined?(@uses_transaction)
        @uses_transaction.include?(method.to_s)
      end

      def use_transactional_fixtures?
        use_transactional_fixtures &&
          !self.class.uses_transaction?(method_name)
      end

      def setup_with_fixtures
        return unless defined?(ActiveRecord::Base) && !ActiveRecord::Base.configurations.blank?

        if pre_loaded_fixtures && !use_transactional_fixtures
          raise RuntimeError, 'pre_loaded_fixtures requires use_transactional_fixtures' 
        end

        @fixture_cache = Hash.new

        # Load fixtures once and begin transaction.
        if use_transactional_fixtures?
          if @@already_loaded_fixtures[self.class]
            @loaded_fixtures = @@already_loaded_fixtures[self.class]
          else
            load_fixtures
            @@already_loaded_fixtures[self.class] = @loaded_fixtures
          end
          ActiveRecord::Base.send :increment_open_transactions
          ActiveRecord::Base.connection.begin_db_transaction

        # Load fixtures for every test.
        else
          @@already_loaded_fixtures[self.class] = nil
          load_fixtures
        end

        # Instantiate fixtures for every test if requested.
        instantiate_fixtures if use_instantiated_fixtures
      end

      alias_method :setup, :setup_with_fixtures

      def teardown_with_fixtures
        return unless defined?(ActiveRecord::Base) && !ActiveRecord::Base.configurations.blank?

        # Rollback changes if a transaction is active.
        if use_transactional_fixtures? && Thread.current['open_transactions'] != 0
          ActiveRecord::Base.connection.rollback_db_transaction
          Thread.current['open_transactions'] = 0
        end
        ActiveRecord::Base.verify_active_connections!
      end

      alias_method :teardown, :teardown_with_fixtures

      def self.method_added(method)
        case method.to_s
        when 'setup'
          unless method_defined?(:setup_without_fixtures)
            alias_method :setup_without_fixtures, :setup
            define_method(:setup) do
              setup_with_fixtures
              setup_without_fixtures
            end
          end
        when 'teardown'
          unless method_defined?(:teardown_without_fixtures)
            alias_method :teardown_without_fixtures, :teardown
            define_method(:teardown) do
              teardown_without_fixtures
              teardown_with_fixtures
            end
          end
        end
      end

      private
        def load_fixtures
          @loaded_fixtures = {}
          fixtures = Fixtures.create_fixtures(fixture_path, fixture_table_names, fixture_class_names)
          unless fixtures.nil?
            if fixtures.instance_of?(Fixtures)
              @loaded_fixtures[fixtures.table_name] = fixtures
            else
              fixtures.each { |f| @loaded_fixtures[f.table_name] = f }
            end
          end
        end

        # for pre_loaded_fixtures, only require the classes once. huge speed improvement
        @@required_fixture_classes = false

        def instantiate_fixtures
          if pre_loaded_fixtures
            raise RuntimeError, 'Load fixtures before instantiating them.' if Fixtures.all_loaded_fixtures.empty?
            unless @@required_fixture_classes
              self.class.require_fixture_classes Fixtures.all_loaded_fixtures.keys
              @@required_fixture_classes = true
            end
            Fixtures.instantiate_all_loaded_fixtures(self, load_instances?)
          else
            raise RuntimeError, 'Load fixtures before instantiating them.' if @loaded_fixtures.nil?
            @loaded_fixtures.each do |table_name, fixtures|
              Fixtures.instantiate_fixtures(self, table_name, fixtures, load_instances?)
            end
          end
        end

        def load_instances?
          use_instantiated_fixtures != :no_instances
        end
    end

  end
end
