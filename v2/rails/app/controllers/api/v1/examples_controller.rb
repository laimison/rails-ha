require 'mysql2/reconnect_with_readonly'

module Api::V1
  class ExamplesController < ApplicationController
    # GET http://IP:PORT/v1/examples
    def index
      distribute_reads(max_lag: 3, lag_failover: true) do
        everything = Example.all
        render json: everything
      end
    end

    # POST http://IP:PORT/v1/examples
    def create
      if params['paramname'] and params['paramname'] =~ /[a-zA-Z0-9]/
        paramname = params['paramname']
      else
        paramname = 'nothing'
      end

      object = Example.new(:name => paramname); object.save

      render json: params
    end

    # DELETE http://IP:PORT/v1/examples
    def destroy
      Example.first.delete if Example.any?

      head 204
    end
  end
end
