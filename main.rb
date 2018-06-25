require "sinatra/base"
require "sinatra/reloader"
require "singleton"
require "sinatra"
require "sinatra/reloader" if development?


require_relative "services"
require_relative "tag_repository"
require_relative "services/feature_extractor"
require_relative "services/feature_indexer"

# set :public_folder, Proc.new { File.join(root, "public") }


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

  Services::FeatureIndexer.instance.index(features)

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



  erb :search_result
end
