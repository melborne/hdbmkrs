# encoding: UTF-8
require "./lib/hateda"
require "json"

set :cache, Dalli::Client.new(ENV['MEMCACHE_SERVERS'],
                              :username => ENV['MEMCACHE_USERNAME'],
                              :password => ENV['MEMCACHE_PASSWORD'],
                              :expires_in => 1.day)

configure do
  APP_TITLE = "Hatena Bookmarkers"
  BLOG = {title: "hp12c", url: "http://d.hatena.ne.jp/keyesberry"}
end

get '/style.css' do
  scss :style
end

get '/' do
  haml :index, :layout => false
end

post '/' do
  user = params[:user]
  redirect "/#{user}"
end

get '/:user.json' do |user|
  redirect '/' unless request.xhr?
  content_type :json
  
  dataset, total = dataset(user.intern)
  if dataset
    data = group_by_top(:marker, 20, dataset)
    {data: data, total: total}.to_json
  else
    nil
  end
end

get '/:user' do
  @user = params[:user].intern

  haml :user
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  
  def dataset(user)
    hb = Hatena::Bookmarks.new(user)
    total = hb.total
    puts "--total: #{total}--"
    val =
      if total == 0
        nil
      elsif total == memcache("total/#{user}").to_i
        puts '--cached data used--'
        memcache("#{user}")
      else
        puts '--data cached--'
        ds = hb.dataset
        set_memcache(user, ds, total)
      end
    [val, total]
  rescue
    puts '--memchache not work--'
    [hb.dataset, total]
  end

  # {marker => [{:url,:title,:marker,:tags,:note,:time},{ }]}
  def group_by_top(key, n, dataset)
    return {} unless dataset
    grouped = dataset.group_by { |h| h[key] }.sort_by { |k, v| -v.size }.take(n)
    Hash[grouped]
  end

  def memcache(key)
    settings.cache.get(key)
  end

  def set_memcache(user, val, total)
    settings.cache.set("total/#{user}", total)
    settings.cache.set("#{user}", val)
    val
  end
end

