require 'sinatra'
require 'redcarpet'

post '/makePage' do
	markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
	puts params[:markdown]
end