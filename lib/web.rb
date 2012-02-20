class Web < Sinatra::Base

  set :public_folder, File.expand_path('../../public', __FILE__) if ENV['RACK_ENV'] == 'development'

  before do
    @static_path = WEB_PATH
  end

  get '/' do
    @section = :stream
    erb :index
  end

  get '/dashboard' do
    @section = :dashboard
    erb :dashboard
  end

  get '/about' do
    @section = :about
    erb :about
  end

  get '/register' do
    Registration.find_or_create_by(:registration_id => params[:id])
    '{}'
  end

  get '/statistics' do
    response = []
    Statistics.where(:interval.gt => Integer(params[:since] || Time.now.to_i - (Statistics.interval * 10))).desc(:interval).each do |doc|
      response << [doc.interval.to_i, doc.tweets.to_i]
    end
    JSON.dump(response)
  end

  get '/tweets' do
    query = Tweet
    if params[:since]
      query = query.where(:created_at.gt => Integer(params[:since]))
      query = query.desc(:created_at)
    else
      query = query.limit(10)
      query = query.desc(:created_at)
    end
    response = []
    query.each do |doc|
      response << { :created_at => doc.created_at.to_i, :user_name => doc.user_name, :text => doc.text}
    end
    JSON.dump(response)
  end

  get '/oshift-twitter/?' do
    redirect to('/')
  end

end