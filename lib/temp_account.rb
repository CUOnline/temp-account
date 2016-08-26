require 'securerandom'

module TempAccount
  class RegistrationError < StandardError; end
  class MergeError < StandardError; end
  class ApiError < StandardError; end

  class User
    attr_accessor :name, :email, :canvas_id, :merge_code

    def initialize(canvas_api, canvas_id=nil)
      @canvas_api = canvas_api
      if canvas_id
        @canvas_id = canvas_id
        self.populate_data
      end
    end


    # If user is initialized with an existing Canvas ID,
    # assign attributes based on existing data from Canvas
    def populate_data
      response = @canvas_api.get("users/#{@canvas_id}/profile")
      @name ||= response.body['name']
      @email ||= response.body['primary_email']
      @canvas_id ||= response.body['id']
    end


    def register(name, email, canvas_account_id)
      @name = name
      @email = email

      api_params = {
        :user => {:name => @name},
        :pseudonym => {
          :unique_id => @email,
          :force_self_registration => true,
          :send_confirmation => true,
        }
      }

      response = @canvas_api.post("accounts/#{canvas_account_id}/users", api_params)

      if response.status != 200
        begin
          # Gee, I sure hope this error format never changes...
          # Look for this error specifically because it's based on user input
          if response.body["errors"]["pseudonym"]["unique_id"][0]["message"]
            raise RegistrationError, "Email address is already in use"
          end
        rescue NoMethodError
          # If the specific sequence of hash keys doesn't exist, it means we got
          # some other unexpected/unhandled error, so give a more generic message
          raise ApiError, "There was a problem creating the account."
        end
      else
        @canvas_id = response.body['id']
      end
    end


    def setup_sandbox(sandbox_account_id)
      api_params = {
        'course' => {
          'name' => "sandbox_#{@name}"
        }
      }
      response = @canvas_api.post("accounts/#{sandbox_account_id}/courses", api_params)

      if response.status != 200
        raise ApiError, 'Account created, but there was a problem creating the sandbox course.'
      end

      course_id = response.body['id']

      api_params = {
        'enrollment' => {
          'user_id' => @canvas_id,
          'type' => 'TeacherEnrollment'
        }
      }
      response = @canvas_api.post("courses/#{course_id}/enrollments", api_params)

      if response.status != 200
        raise ApiError, 'Account created, but there was a problem enrolling in the sandbox course.'
      end
    end


    def set_custom_data(data, scope='temp-account-code', namespace='wolf')
      api_params = {:ns => namespace, :data => data}
      url = "users/#{@canvas_id}/custom_data/#{scope}"

      @canvas_api.put(url, api_params) do |req|
        req.headers['Content-Type'] = 'multipart/form-data'
      end
    end


    def get_custom_data(scope='temp-account-code', namespace='wolf')
      response = @canvas_api.get("users/#{@canvas_id}/custom_data/#{scope}", {:ns => namespace})
      response.body['data']
    end


    def merge_code
      @merge_code ||= self.get_custom_data || "#{@canvas_id}-#{SecureRandom.uuid}"
    end
  end
end
