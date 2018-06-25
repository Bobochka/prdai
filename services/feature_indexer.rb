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

    responses = requests.map do |request|

      p request.response.body

      # JSON().map(&:to_f)
    end
  end

  def search(boxes_with_feature)
    result = boxes_with_feature.clone

    hydra = ::Typhoeus::Hydra.new
    requests = boxes_with_feature.map do |elem|
      url = url('search')
      options = { method: :post, body: JSON({ k: 3, vectors: elem[:feature] }) }

      req = ::Typhoeus::Request.new(url, options)
      hydra.queue(req)
      
      req
    end
    hydra.run

    result.each do |elem|
      elem.delete(:feature)
    end

    responses = requests.map.with_index do |request, i|
      res = JSON(request.response.body)

      # p("res: #{res}")
      # p("="*50)

      if res.size > 0
        neighbors = res[0]['neighbors']

        first_neighbor = neighbors[0]
        another_neighbor = neighbors.find do |neighbor|
          neighbor['id'] != first_neighbor['id']
        end

        p("first_neighbor: #{first_neighbor}")
        p("another_neighbor: #{another_neighbor}")

        if another_neighbor
          score = 1 - first_neighbor['score'].to_f / another_neighbor['score'].to_f
        else
          score = 1
        end

        # groups = 
        #   neighbors.group_by do |neighbor|
        #     neighbor['id']
        #   end
        
        # p("groups: #{groups}")

        # if first_neighbor
        #   tag_id = first_neighbor[0]['id']
        #   score = first_neighbor[0]['score']
        # end

        # second_neighbor = res[1]['neighbors']
        # if second_neighbor
        #   tag_id = second_neighbor[0]['id']
        #   score = second_neighbor[0]['score']
        # end
      end

      result[i][:tag] = { tag_id: first_neighbor['id'], score: score }
    end

    result
  end

  private

  def url(path)
    base_url + '/' + path
  end

  def base_url
    "http://192.168.201.226:7687/faiss"
  end
end