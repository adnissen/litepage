require 'sinatra'
require 'redcarpet'
require 'mongo'
require 'uri'

configure do
	def get_connection
	  return @db_connection if @db_connection
	  db = URI.parse(ENV['MONGOHQ_URL'])
	  db_name = db.path.gsub(/^\//, '')
	  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
	  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
	  @db_connection
	end

	db = get_connection

	puts "Collections"
	puts "==========="
	collections = db.collection_names
	puts collections
end

post '/makePage' do
	markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
	puts params[:markdown]
end