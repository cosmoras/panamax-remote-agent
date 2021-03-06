require 'spec_helper'

describe ApplicationController do

    describe 'handling StandardError exceptions' do

    controller do
      def index
        raise StandardError, 'oops'
      end
    end

    it 'logs some info at the error level' do
      expect(controller.logger).to receive(:error).once
      get :index
    end

    it 'returns a 500 status code' do
      get :index
      expect(response.status).to eq 500
    end

    it 'renders the error message in the response body' do
      get :index
      expect(response.body).to eq({ message: 'oops' }.to_json)
    end
  end

  describe 'handling Faraday::Error::ConnectionFailed exceptions' do

    controller do
      def index
        raise Faraday::Error::ConnectionFailed, 'oops'
      end
    end

    it 'returns a 500 status code' do
      get :index
      expect(response.status).to eq 500
    end

    it 'renders the adapter connection error in the response body' do
      get :index
      expect(response.body).to eq(
        { message: I18n.t(:adapter_connection_error) }.to_json)
    end
  end

  describe '#handle_exception' do

    context 'when a message is provided' do

      controller do
        def index
          raise StandardError, 'oops'
        rescue => ex
          handle_exception(ex, 'uh-oh')
        end
      end

      it 'renders the provided message in the response body' do
        get :index
        expect(response.body).to eq({ message: 'uh-oh' }.to_json)
      end

      it 'returns a 500 status code' do
        get :index
        expect(response.status).to eq 500
      end
    end

    context 'when a translated message key is provided' do

      controller do
        def index
          raise StandardError, 'oops'
        rescue => ex
          handle_exception(ex, :hello)
        end
      end

      it 'renders the translated message in the response body' do
        get :index
        expect(response.body).to eq({ message: I18n.t(:hello) }.to_json)
      end

      it 'returns a 500 status code' do
        get :index
        expect(response.status).to eq 500
      end
    end

    context 'when a translated message key is provided that doesnt exist' do

      controller do
        def index
          raise StandardError, 'oops'
        rescue => ex
          handle_exception(ex, :foo)
        end
      end

      it 'renders the message key as a string in the response body' do
        get :index
        expect(response.body).to eq({ message: 'foo'}.to_json)
      end

      it 'returns a 500 status code' do
        get :index
        expect(response.status).to eq 500
      end
    end

    context 'when a block is provided that does not render' do

      controller do
        def index
          raise StandardError, 'oops'
        rescue => ex
          handle_exception(ex) { logger.warn('debug information') }
        end
      end

      it 'invokes the block' do
        expect(controller.logger).to receive(:warn).once
        get :index
      end

      it 'returns a 500 status code' do
        get :index
        expect(response.status).to eq 500
      end

      it 'renders the error message in the response body' do
        get :index
        expect(response.body).to eq({ message: 'oops' }.to_json)
      end
    end

    context 'when a block is provided that renders a response' do

      controller do
        def index
          raise StandardError, 'oops'
        rescue => ex
          handle_exception(ex) { render text: 'whoops', status: 777 }
        end
      end

      it 'invokes the block in lieu of the defaut render logic' do
        get :index
        expect(response.status).to eq 777
        expect(response.body).to eq 'whoops'
      end
    end
  end
end
