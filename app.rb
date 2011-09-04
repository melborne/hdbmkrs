# encoding: UTF-8
require "./lib/bookmarks"

set :cache, Dalli::Client.new(ENV['MEMCACHE_SERVERS'],
                              :username => ENV['MEMCACHE_USERNAME'],
                              :password => ENV['MEMCACHE_PASSWORD'],
                              :expires_in => 1.day)

configure do
  APP_TITLE = "HateDa Bookmark Stars"
end

get '/style.css' do
  scss :style
end

get '/' do
  haml :index
end

post '/' do
  user = params[:user]
  redirect "/#{user}"
end

get '/:user' do
  @user = params[:user].intern
  @dataset = dataset
  markers = stat_by(:marker) { |k, cnt| cnt > 3 }
  @markers = map_url(markers, :marker)
  entries = stat_by(:title) { |k, cnt| cnt > 10 }
  @entries = map_url(entries, :entry)

  haml :user
end

helpers do
  def dataset
    hb = Hatena::Bookmarks.new(@user)
    @total = hb.total
    if @total == memcache("total/#{@user}").to_i
      memcache("#{@user}")
    else
      memcache = hb.dataset
    end
  end

  # key must in :url, :title, :marker, :tags, :note, :time
  # accept block for filtering key or value of the data
  def stat_by(key, &blk)
    @dataset.map { |ent| ent[key] }
            .inject(Hash.new(0)) { |h, k| h[k] +=1; h }
            .select { |k, cnt| blk ? yield(k, cnt) : true  }
            .sort_by { |_,v| -v }
  end

  def map_url(data, type)
    data.map do |key, n|
      url =
        case type
        when :entry;  @dataset.detect { |h| h[:title] == key }[:url]
        when :marker; "http://d.hatena.ne.jp/#{key}"
        else
          raise ArgumentError, "type not found."
        end
      {key: key, url: url, count: n}
    end
  end

  def memcache(key)
    settings.cache.get(key)
  end

  def memcache=(val)
    settings.cache.set("total/#{@user}", @total)
    settings.cache.set("#{@user}", val)
    val
  end
end


