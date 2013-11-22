require 'sinatra'
require 'redcarpet'
require 'mongo'
require 'uri'

include Mongo

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
  File.read(File.join('public', 'index.html'))
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

get '/:name/edit' do
  page = pages.find_one("name" => "#{params[:name]}")
  if page == nil
    "404"
  else
    "editing"
  end
end

post '/makePage' do
  # grab the markdown from their post request
  markdown = params[:markdown]
  pageName = params[:name]
  password = params[:password]
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