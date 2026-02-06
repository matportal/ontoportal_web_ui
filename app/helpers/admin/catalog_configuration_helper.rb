module Admin::CatalogConfigurationHelper

  def description_tooltip(label, description, show_tooltip: true)
    return '' if description.nil? || description.empty?
    content_tag(:div) do
      tooltip_span = render(Display::InfoTooltipComponent.new(text: description_tooltip_help_text(label, description)))
      html = content_tag(:span, tooltip_span, class: 'ml-1') if show_tooltip
      html
    end
  end

  def attr_metadata_header_label(attr, label = nil, show_tooltip: true)
    label ||= attr.label
    return '' if label.nil? || label.empty?

    content_tag(:div) do
      tooltip_span = render(Display::InfoTooltipComponent.new(text: attribute_metdata_help_text(attr)))
      html = content_tag(:span, label)
      html += content_tag(:span, '*', class: "text-danger") if attr.required?
      html += content_tag(:span, tooltip_span, class: 'ml-1') if show_tooltip
      html
    end
  end

  def get_theme_taxonomy_ontologies
    params = {
      include: "themeTaxonomy",
      display_links: false,
      display_context: false,
      _ts: Time.current.to_i
    }

    result = LinkedData::Client::HTTP.get("#{LinkedData::Client.settings.rest_url}/", params).to_hash
    theme_taxonomy = result[:themeTaxonomy] || result["themeTaxonomy"]

    # `themeTaxonomy` can be a String (e.g. "UNESCO Thesaurus") or an Array of URLs.
    # Normalize and only keep ontology URLs pointing to this REST instance.
    rest_base = LinkedData::Client.settings.rest_url.to_s.chomp("/")
    Array(theme_taxonomy)
      .filter { |u| u.is_a?(String) && u.strip.start_with?(rest_base) }
      .map { |u| u.strip.split('/').last }
  rescue StandardError => e
    Rails.logger.warn("get_theme_taxonomy_ontologies failed: #{e.class}: #{e.message}") if defined?(Rails)
    []
  end

  private

  def description_tooltip_help_text(label, description)
    title = content_tag(:span, "#{label}")
    render SummarySectionComponent.new(title: title, show_card: false) do
      help_text = ''
      unless description.nil? || description.empty?
        help_text += render(FieldContainerComponent.new(label: t('submission_inputs.help_text'), value: simple_format(description)))
      end

      help_text
    end
  end

  def attribute_metdata_help_text(attr)
    label = attr.label
    help = attr.helpText
    required = attr.required?
    attribute = !attr.namespace.nil? ? "#{attr.namespace}:#{attr.attribute}" : "bioportal:#{attr.attribute}"

    title = content_tag(:span, "#{label} (#{attribute})")
    title += content_tag(:span, 'required', class: 'badge badge-danger mx-1') if required

    render SummarySectionComponent.new(title: title, show_card: false) do
      help_text = ''
      unless attr.metadataMappings.nil?
        help_text += render(FieldContainerComponent.new(label: t('submission_inputs.equivalents'), value: attr.metadataMappings.join(', ')))
      end

      unless attr.enforce.nil? || attr.enforce.empty?
        help_text += render(FieldContainerComponent.new(label: t('submission_inputs.validators'), value: attr.enforce.map do |x|
          content_tag(:span, x.humanize, class: 'badge badge-primary mx-1')
        end.join.html_safe))
      end

      unless attr['helpText'].nil?
        help_text += render(FieldContainerComponent.new(label: t('submission_inputs.help_text'), value: help.html_safe))
      end

      help_text
    end
  end

end

