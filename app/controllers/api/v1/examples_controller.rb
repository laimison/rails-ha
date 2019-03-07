module Api::V1
  class ExamplesController < ApplicationController
    # GET http://IP:PORT/v1/examples
    def index
      output = { example_get: params }
      logger.info("I have received GET: #{output}")
      render json: output
      # render json: Example.all
    end

    # POST http://IP:PORT/v1/examples
    def create
      output = { example_get: params }
      logger.info("I have received POST: #{output}")

      render json: output
    end
  end
end
