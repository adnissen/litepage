require 'sinatra'
require 'redcarpet'
require 'mongo'
require 'uri'
require 'digest/sha1'
require 'json'

include Mongo

#set :static_cache_control, [:public, :max_age => 300]

class Encode
  def initialize(key)
    @salt= key
  end

  def encrypt(text)
     Digest::SHA1.hexdigest("--#{@salt}--#{text}--")
  end
end

=begin
def get_connection
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  @db_connection
end

e = Encode.new(ENV['HASH_KEY'])
db = get_connection
=end

# this is just for testing purposes, of course the mongo server should be the one on heroku
mongo_client = MongoClient.new("localhost", 27017)
db = mongo_client.db("mydb")
db = MongoClient.new("localhost", 27017).db("mydb")

e = Encode.new("This is a very hard key.")

# a document in the pages collection is just a page title with the markdown
pages = db.collection("pages")

get '/' do
  File.read(File.join(settings.public_folder, 'index.html'))
end

post '/makePage' do
  # grab the markdown from their post request
  markdown = params[:markdown]
  pageName = params[:name]
  password = e.encrypt(params[:password])
  puts "starting to make the page"
  if markdown == nil or pageName == nil or password == nil
    puts "error, bad post request"
    return
  end
  if pages.find("name" => pageName).count != 0
    puts "there's already a page with that name"
    return
  end
  doc = {"name" => pageName, "markdown" => markdown, "password" => password}
  id = pages.insert(doc)
  puts "page created: " + id.to_s
end

get '/:name' do
  page = pages.find_one("name" => "#{params[:name]}")
  if page == nil
    "404"
  else
    File.read(File.join(settings.public_folder, 'pageView.html'))
  end
end

post '/:name' do
  page = pages.find_one("name" => "#{params[:name]}")
  if page == nil
    "404"
  else
    content_type :json
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
    {:content => markdown.render(page['markdown'])}.to_json
  end
end

get '/:name/auth' do
  page = pages.find_one("name" => "#{params[:name]}")
  if page == nil
    '404'
  else
    File.read(File.join(settings.public_folder, 'auth.html'))
  end
end

post '/:name/auth' do
  page = pages.find_one("name" => "#{params[:name]}")
  if page['password'] == e.encrypt(params[:hash])
    content_type :json 
    {:redirect => e.encrypt(params[:hash])}.to_json
  end
end

get '/:name/auth/:key' do
  page = pages.find_one("name" => "#{params[:name]}")
  if page['password'] == "#{params[:key]}"
    File.read(File.join(settings.public_folder, 'edit.html'))
  end
end

post '/:name/auth/:key' do
  # THERE IS AN ERROR THROWN HERE, BUT THE UPDATE GOES THROUGH FINE. I HAVE NO IDEA WHY THAT IS

  # ERROR TypeError: no implicit conversion of Array into String
  markdown = params[:markdown]
  page = pages.find_one("name" => "#{params[:name]}")
  if page['password'] == "#{params[:key]}"
    pages.update({"name" => "#{params[:name]}"}, {"$set" => {"markdown" => markdown}})
  end
  "done"
end