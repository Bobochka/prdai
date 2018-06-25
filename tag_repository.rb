class TagRepository
  include Singleton

  def initialize
    @counter = 0
    @tag_to_id = {}
    @id_to_tag = {}
    @mtx = Monitor.new
  end

  def create(tag)
    @mtx.synchronize do
      @counter += 1
      @tag_to_id[tag] = @counter
      @id_to_tag[@counter] = tag
      @counter
    end
  end

  def find_by_id(id)
    @id_to_tag[id]
  end
end