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

e = Encode.new("This is a very hard key.")

=begin
def get_connection
  return @db_connection if @db_connection
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
  @db_connection
end

db = get_connection
=end

# this is just for testing purposes, of course the mongo server should be the one on heroku
mongo_client = MongoClient.new("localhost", 27017)
db = mongo_client.db("mydb")
db = MongoClient.new("localhost", 27017).db("mydb")

# a document in the pages collection is just a page title with the markdown
pages = db.collection("pages")

get '/' do
  File.read(File.join(settings.public_folder, 'index.html'))
end

get '/:name' do
  page = pages.find_one("name" => "#{params[:name]}")
  if page == nil
  	"404"
  else
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
    markdown.render(page['markdown'])
  end
end

get '/:name/auth' do
  page = pages.find_one("name" => "#{params[:name]}")
  if page == nil
    '404'
  else
    File.read(File.join(settings.public_folder, 'edit.html'))
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
    puts "free to edit"
  end
end

post '/makePage' do
  # grab the markdown from their post request
  markdown = params[:markdown]
  pageName = params[:name]
  password = e.encrypt(params[:password])
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