require 'singleton'
require 'typhoeus'
require 'typhoeus/hydra'

# for indexing:
#   ‘/get_feature’
#   input: image (as uploaded file)
#   output: JSON holding array of 512 floating points (the numbers are in strings, since i’m unable to serialize floats)
  
# for query:
#   ‘/multi_extraction’ 
#   gets image (as upload file)
#   returns JSON a single array, each element in the array is a dictionary:
#   ‘bbox’: [x,y,h,w]    (the bounding box of the element)
#   ‘feature’: 512 floating point array (like in ‘/get_feature’)

class Services::FeatureExtractor
  include Singleton

  def from_training_set(files)
    hydra = ::Typhoeus::Hydra.new
    requests = files.map do |f|
      url = url('get_feature')
      options = { 
        method: :post, 
        body: { image: f } 
      }

      req = ::Typhoeus::Request.new(url, options)
      hydra.queue(req)
      req
    end
    hydra.run

    responses = requests.map do |request|
      JSON(request.response.body).map(&:to_f)
    end
  end

  def from_uploadable(file)
    response = ::Typhoeus.post(
      url('multi_extraction'),
      method: :post,
      body: { image: file }
    )

    JSON(response.body).map do |elem|
      {
        box: elem['bbox'],
        feature: elem['feature'].map(&:to_f)
      }
    end
  end

  private

  def url(path)
    base_url + '/' + path
  end

  def base_url
    "http://192.168.201.226:7687"
  end
end