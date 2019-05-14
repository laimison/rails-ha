require 'mysql2/reconnect_with_readonly'

module Api::V1
  class ExamplesController < ApplicationController
    # GET http://IP:PORT/v1/examples
    def index
      # render json: params['test']

      distribute_reads(max_lag: 3, lag_failover: true) do
        everything = Example.all
        render json: everything
      end
      # Example.last.delete if Example.any?
    end

    # POST http://IP:PORT/v1/examples
    def create
      object = Example.new(:name => 'test'); object.save

      render json: params
    end
  end
end
