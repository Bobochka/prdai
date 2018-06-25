require 'singleton'

class Services::FeatureIndexer
  include Singleton

  def index(id, vectors)
    return

    hydra = ::Typhoeus::Hydra.new
    requests = vectors.map do |feature|
      url = url('get_feature')
      options = { method: :post, body: { id: id, feature: feature } }

      req = ::Typhoeus::Request.new(url, options)
      hydra.queue(req)
      req
    end
    hydra.run

    # responses = requests.map do |request|
    #   JSON(request.response.body).map(&:to_f)
    # end
  end

  def search(vectors)
    hydra = ::Typhoeus::Hydra.new
    requests = vectors.map do |feature|
      url = url('search')
      options = { method: :post, body: { k: 1, feature: feature } }

      req = ::Typhoeus::Request.new(url, options)
      hydra.queue(req)
      req
    end
    hydra.run

    responses = requests.map do |request|
      JSON(request.response.body)
    end
  end

  private

  def url(path)
    base_url + '/' + path
  end

  def base_url
    "http://localhost:5000"
  end
end