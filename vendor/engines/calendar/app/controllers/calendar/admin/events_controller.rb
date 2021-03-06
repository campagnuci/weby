module Calendar
  class Admin::EventsController < Calendar::ApplicationController
    before_action :require_user
    before_action :check_authorization
    before_action :event_types, only: [:new, :edit, :create, :update]

    respond_to :html, :js, :json

    helper_method :sort_column

    def index
      @events = get_events
      respond_with(:admin, @events) do |format|
        if params[:template]
          format.js { render "#{params[:template]}" }
          format.html { render partial: "#{params[:template]}", layout: false }
        end
        format.json { render json: Calendar::Event.as_fullcalendar_json(@events, true) }
      end
    end

    def get_events
      params[:direction] ||= 'desc'
      # Vai ao banco por linha para recuperar
      # tags e locales
      events = current_site.events.
        search(params[:search], 1) # 1 = busca com AND entre termos

      events = events.order(sort_column + ' ' + sort_direction)
        .page(params[:page]).per(params[:per_page])
    end
    private :get_events

    def recycle_bin
      params[:sort] ||= 'calendar_events.deleted_at'
      params[:direction] ||= 'desc'
      @events = current_site.events.trashed.includes(:user).
        order("#{params[:sort]} #{sort_direction}").
        page(params[:page]).per(params[:per_page])
    end

    def show
      @event = current_site.events.find(params[:id]).in(params[:show_locale])
    end

    def new
      @event = current_site.events.new
    end

    def create
      @event = current_site.events.new(events_params)
      @event.user = current_user
      @event.save
      record_activity('created_event', @event)
      respond_with(:admin, @event)
    end

    def edit
      @event = current_site.events.find(params[:id])
    end

    def update
      params[:event][:related_file_ids] ||= []
      @event = current_site.events.find(params[:id])
      @event.update(events_params)
      record_activity('updated_event', @event)
      respond_with(:admin, @event)
    end

    def event_types
      @event_types = Calendar::Event::EVENT_TYPES.map { |el| [t("calendar.admin.events.form.#{el}"), el] }
    end
    private :event_types

    def destroy
      @event = current_site.events.unscoped.find(params[:id])
      if @event.trash
        if @event.persisted?
          record_activity('moved_event_to_recycle_bin', @event)
          flash[:success] = t('moved_event_to_recycle_bin')
        else
          record_activity('destroyed_event', @event)
          flash[:success] = t('successfully_deleted')
        end
      else
        flash[:error] = @event.errors.full_messages.join(', ')
      end

      redirect_to @event.persisted? ? admin_events_path : recycle_bin_admin_events_path
    end

    def recover
      @event = current_site.events.trashed.find(params[:id])
      if @event.untrash
        flash[:success] = t('successfully_restored')
      end
      record_activity('restored_event', @event)
      redirect_to :back
    end

    private

    def sort_column
      params[:sort] || 'calendar_events.id'
    end

    def events_params
      params.require(:event).permit(:begin_at, :end_at, :email, :url,
                                   :kind, :category_list, :image,
                                   { i18ns_attributes: [:id, :locale_id, :name,
                                       :information, :place, :_destroy],
                                     related_file_ids: [] })
    end
  end
end
