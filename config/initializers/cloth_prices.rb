begin
  CLOTHS_PRICES = JSON.parse(ENV['CLOTHS_PRICES'] || '{}').freeze
rescue JSON::ParserError => e
  Rails.logger.error "Failed to parse CLOTHS_PRICES: #{e.message}"
  CLOTHS_PRICES = {}.freeze
end
