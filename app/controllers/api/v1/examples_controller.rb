module Api::V1
  class ExamplesController < ApplicationController
    # GET http://IP:PORT/v1/examples
    def index
      # render json: params['test']
      render json: Example.all

      Example.last.delete if Example.any?
    end

    # POST http://IP:PORT/v1/examples
    def create
      object = Example.new(:string => 'test'); object.save

      render json: params
    end
  end
end
