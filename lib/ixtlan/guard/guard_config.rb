require 'yaml'
module Ixtlan
  module Guard
    class Config

      def initialize(options = {})
        @guards_dir = options[:guards_dir]
        @load_method = options[:cache] ? :cached_load_from_yaml_file : :load_from_yaml_file
        raise GuardException.new("guards directory does not exists: #{@guards_dir}") unless File.directory?(@guards_dir)
      end

      def allowed_groups(resource, action)
        if resource && action
          groups = send(@load_method, resource.to_s)
          groups[action.to_s] || groups["defaults"] || []
        else
          []
        end
      end

      def has_guard?(resource)
        File.exists? yaml_file(resource)
      end

      def map_of_all
        result = {}
        Dir[File.join(@guards_dir, "*_guard.yml")].each do |file|
          result.merge!(YAML.load_file(file))
        end
        result
      end

      private
      
      def cached_load_from_yaml_file(resource)
        @cache ||= {}
        @cache[resource] ||= load_from_yaml_file(resource)
      end

      def yaml_file(resource)
        File.join(@guards_dir, "#{resource}_guard.yml")
      end

      def load_from_yaml_file(resource)
        file = yaml_file(resource)
        if File.exists? file
          YAML.load_file(file)[resource] || {}
        else
          {}
        end
      end
    end
  end
end
