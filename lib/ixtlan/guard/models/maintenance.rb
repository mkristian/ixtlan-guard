unless String.respond_to? "plural"
  class String
    def plural
      self + "s"
    end
  end
end

module Ixtlan
  module SerializableModel
    def self.included(model)
      model.send :include, ActiveModel::Serializers::JSON
      model.send :include, ActiveModel::Serializers::Xml
    end

    def attributes=(attributes)
      attributes.each do |k, v|
        if k == k.plural
          v = case v
              when String
                [v]
              when Array
                v
              when Hash
                v.values.flatten
              end
        end
        send("#{k}=", v)
      end
    end
    
    def attributes
      map = instance_variables.collect do |name|
        [name[1,1000], send(name[1,1000].to_sym)]
      end.reject do |x| 
        x[1] == nil
      end
      Hash[map]
    end
  end
end

module Ixtlan
  module Guard
    module Models
      class Maintenance

        include Ixtlan::SerializableModel
        
        attr_accessor :groups
        
      end
    end
  end
end
