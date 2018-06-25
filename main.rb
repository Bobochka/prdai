require "sinatra/base"
require "singleton"
require "sinatra"
require "sinatra/reloader" if development?


require_relative "services"
require_relative "tag_repository"
require_relative "services/feature_extractor"
require_relative "services/feature_indexer"

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

get '/' do
  erb :index, layout: :layout
end

get '/tagify' do
  erb :tagify, layout: :layout
end

post '/upload_tag' do
  tag = params["tag"]
  id = TagRepository.instance.create(tag)

  files = params["pics"].map do |pic_param|
    filename = pic_param["filename"]
    file = pic_param["tempfile"]
    folder = File.join(Dir.pwd, 'public', "#{id}")

    res = Dir.mkdir(folder, 0755) unless File.exists?(folder)

    File.open("#{folder}/#{filename}", 'wb') do |f|
      f.write(file.read)
    end

    pic_param["tempfile"]
  end

  features = Services::FeatureExtractor.instance.from_training_set(files)

  p features

  Services::FeatureIndexer.instance.index(id, features)

  erb "uploaded with #{id}<br><br>#{features}"
end

post '/search' do
  filename = params['pic']["filename"]
  file = params['pic']["tempfile"]

  folder = File.join(Dir.pwd, 'public')
  @file_name = "#{Time.now.to_i}"
  @file_path = "#{folder}/#{@file_name}"

  File.open(@file_path, 'wb') do |f|
    f.write(file.read)
  end

  boxes_with_feature = Services::FeatureExtractor.instance.from_uploadable(file)

  # boxes_with_feature.each do |elem|
  #   p elem[:feature]
  # end

  boxes_with_feature_scores = Services::FeatureIndexer.instance.search(boxes_with_feature)

  p("res: #{boxes_with_feature_scores}")

  res = boxes_with_feature_scores.map do |elem|
    score = elem[:tag][:score]
    next nil if score > 0.8 
    tag_name = TagRepository.instance.find_by_id(elem[:tag][:tag_id])

    { boundingBox: elem[:box], tag: tag_name,  }
  end.compact

  # { boundingBox: [50, 50, 100, 100], tag: "hello" }

    # elem[:feature]

  # p boxes_with_feature

  erb JSON(res)
end
