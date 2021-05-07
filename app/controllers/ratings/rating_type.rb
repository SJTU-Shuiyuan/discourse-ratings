# frozen_string_literal: true
class DiscourseRatings::RatingTypeController < ::Admin::AdminController
  before_action :validate_existence, only: [:create, :update, :destroy]
  before_action :validate_name, only: [:update, :create]
  before_action :validate_type, only: [:update, :create]

  MIN_TYPE_LENGTH = 2
  MIN_NAME_LENGTH = 2

  def index
    render_serialized(DiscourseRatings::RatingType.all, DiscourseRatings::RatingTypeSerializer)
  end

  def create
    handle_render(DiscourseRatings::RatingType.create(type_params[:type], type_params[:name]))
  end

  def update
    handle_render(DiscourseRatings::RatingType.set(type_params[:type], type_params[:name]))
  end

  def destroy
    handle_render(Jobs.enqueue(:destroy_rating_type, type: type_params[:type]))
  end

  private

  def type_params
    params.permit(:type, :name)
  end

  def validate_existence
    exists = DiscourseRatings::RatingType.exists?(type_params[:type])

    if (exists && action_name == "create") ||
        (!exists && ["update", "destroy"].include?(action_name))
      raise Discourse::InvalidParameters.new(:type)
    end
  end

  def validate_type
    if type_params[:type].length < MIN_TYPE_LENGTH ||
        type_params[:type] == DiscourseRatings::RatingType::NONE
      raise Discourse::InvalidParameters.new(:type)
    end
  end

  def validate_name
    if type_params[:name].length < MIN_NAME_LENGTH
      raise Discourse::InvalidParameters.new(:name)
    end
  end

  def handle_render(success)
    if success
      render_json_dump(success_json)
    else
      render_json_dump(failed_json)
    end
  end
end
