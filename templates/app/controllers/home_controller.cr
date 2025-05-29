class HomeController < ApplicationController
  actions :index

  def index
    render plain: "Welcome to Takarik!"
  end
end
