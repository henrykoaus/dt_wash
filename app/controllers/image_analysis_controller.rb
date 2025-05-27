require 'httparty'
class ImageAnalysisController < ApplicationController
  include Pundit::Authorization
  skip_after_action :verify_policy_scoped, only: [:analyze]
  skip_after_action :verify_authorized, only: [:analyze]
  CLOTH_TYPE_KEYWORDS = JSON.parse(ENV['CLOTH_TYPE_KEYWORDS']).freeze

  def analyze
    image_file = params[:image]
    validate_file!(image_file)
    vision_response = call_google_vision_api(image_file)
    analysis_result = process_vision_response(vision_response)
    # p "Analysis Result: #{analysis_result.inspect}"
    render json: analysis_result
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def validate_file!(file)
    return if file&.content_type&.start_with?('image/') && file.size <= 5.megabytes

    raise 'Invalid file format or size (max 5MB)'
  end

  def call_google_vision_api(file)
    base64_image = Base64.strict_encode64(file.read)

    response = HTTParty.post(
      "https://vision.googleapis.com/v1/images:annotate?key=#{ENV['GOOGLE_API_KEY']}",
      body: {
        requests: [{
                     image: { content: base64_image },
                     features: [
                       { type: 'LABEL_DETECTION', maxResults: 20 },
                       { type: 'OBJECT_LOCALIZATION', maxResults: 10 },
                       { type: 'IMAGE_PROPERTIES', maxResults: 10 },
                       { type: 'WEB_DETECTION', maxResults: 5 }
                     ]
                   }]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    raise response['error']['message'] if response.code != 200
    response.parsed_response
  end

  def process_vision_response(response)
    # p "Response: #{response.inspect}"
    labels = response.dig('responses', 0, 'labelAnnotations') || []
    objects = response.dig('responses', 0, 'localizedObjectAnnotations') || []
    web_entities = response.dig('responses', 0, 'webDetection', 'webEntities') || []
    colors = response.dig('responses', 0, 'imagePropertiesAnnotation', 'dominantColors', 'colors') || []

    combined_terms = process_combined_terms(labels, objects, web_entities)

    {
      cloth_type: detect_cloth_type(combined_terms),
      color: detect_dominant_color(colors),
      cloth_types: CLOTH_TYPES,
      colors: COLORS,
      cloth_prices: CLOTHS_PRICES
    }
  end

  def process_combined_terms(labels, objects, web_entities)
    terms = []

    # Process labels
    labels.each { |l| terms << { term: l['description'], score: l['score'], source: :label } }

    # Process objects
    objects.each { |o| terms << { term: o['name'], score: o['score'], source: :object } }

    # Process web entities
    web_entities.each do |we|
      next unless we['description']
      terms << { term: we['description'], score: we['score'] || 0.7, source: :web }
    end

    terms.uniq { |t| t[:term] }
  end

  def detect_cloth_type(terms)
    scores = Hash.new(0)

    terms.each do |term_info|
      CLOTH_TYPE_KEYWORDS.each do |cloth_type, keywords|
        keywords.each do |keyword|
          if fuzzy_match?(term_info[:term], keyword)
            score = calculate_term_score(term_info, keyword)
            scores[cloth_type] += score
          end
        end
      end
    end

    return 'Unknown' if scores.empty?

    top_candidates = scores.sort_by { |_, v| -v }
    determine_best_match(top_candidates)
  end

  def fuzzy_match?(term, keyword)
    term.downcase.include?(keyword.downcase)
  end

  def calculate_term_score(term_info, keyword)
    base_score = term_info[:score]
    source_weight = case term_info[:source]
                    when :object then 1.5
                    when :web then 1.2
                    else 1.0
                    end
    keyword_weight = CLOTH_TYPE_KEYWORDS.find { |k, v| k == keyword } ? 1.0 : 0.8

    base_score * source_weight * keyword_weight
  end

  def determine_best_match(candidates)
    # print "Candidates: #{candidates.inspect}"
    # return candidates.first[0] if candidates.size == 1
    #
    # # Require at least 25% score difference for confidence
    # if candidates.first[1] > (candidates[1][1] * 1.25)
    #   candidates.first[0]
    # else
    #   'Unknown'
    # end
    return 'Unknown' if candidates.empty?
    candidates.first[0]
  end

  def detect_dominant_color(colors)
    return 'Unknown' if colors.empty?

    dominant = colors.max_by { |c| c['pixelFraction'] }['color']
    h, s, l = rgb_to_hsl(dominant['red'], dominant['green'], dominant['blue'])
    determine_color_name(h, s, l)
  end

  def rgb_to_hsl(r, g, b)
    r /= 255.0
    g /= 255.0
    b /= 255.0

    max = [r, g, b].max
    min = [r, g, b].min
    delta = max - min

    h = 0.0
    s = 0.0
    l = (max + min) / 2.0

    if delta != 0.0
      s = delta / (1 - (2 * l - 1).abs)
      case max
      when r then h = 60 * ((g - b) / delta % 6)
      when g then h = 60 * ((b - r) / delta + 2)
      when b then h = 60 * ((r - g) / delta + 4)
      end
    end

    [h.round, (s * 100).round, (l * 100).round]
  end

  def determine_color_name(h, s, l)
    if s < 10
      return 'White' if l > 90
      return 'Black' if l < 10
      return 'Gray'
    end

    hue_ranges = [
      { name: 'Red', range: [0, 15] },
      { name: 'Orange', range: [16, 45] },
      { name: 'Yellow', range: [46, 65] },
      { name: 'Green', range: [66, 165] },
      { name: 'Blue', range: [166, 265] },
      { name: 'Purple', range: [266, 310] },
      { name: 'Pink', range: [311, 345] },
      { name: 'Red', range: [346, 360] }
    ]

    category = hue_ranges.find { |range| h.between?(*range[:range]) }

    modifier = []
    modifier << 'Pale' if s < 33
    modifier << 'Vibrant' if s > 66
    modifier << 'Dark' if l < 33
    modifier << 'Light' if l > 66

    [modifier.join(' '), category&.[](:name) || 'Unknown'].reject(&:empty?).join(' ')
  end
end
