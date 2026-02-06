# Deployment patch: guard against missing metadata categories from API
Rails.application.config.to_prepare do
  OntologiesController.class_eval do
    def properties_hash_values(properties, sub: @submission_latest, custom_labels: {})
      return {} if sub.nil? || properties.nil?
      properties.map { |x| [x.to_s, [sub.send(x.to_s), custom_labels[x.to_sym]]] }.to_h
    end
  end
end
