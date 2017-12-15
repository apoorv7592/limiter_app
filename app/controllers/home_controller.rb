class HomeController < ApplicationController

  def index
    render json: { message: "ok"}
  end

end