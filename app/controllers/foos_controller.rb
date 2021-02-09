class FoosController < ApplicationController
  before_action :set_foo, only: %i[ show edit update destroy ]

  content_security_policy only: [:index] do |config, foo|
    config.connect_src ->() do
      # This analog would replace the `add_csp_exceptions` pattern.

      # look at me! I'm in an "action" context here.
      # so I can see cookies, the request, flipper, etc.
      SecureRandom.hex(16) + ".com"
    end
  end

  # GET /foos or /foos.json
  def index
    # media source was not defined, so it needs to inherit what was in default-src
    append_content_security_policy_directives(media_src: %w(foo.com))

    # worker source is set to none, so we need to override that value
    append_content_security_policy_directives(worker_src: %w(foo.com))

    # results in
    # font-src 'self' https: data:;
    # img-src 'self' https: data:;
    # object-src 'none';
    # script-src 'self' https:;
    # style-src 'self' https:;
    # connect-src e84084ace36797dfa21d0ad79c9fcde8.com; <- set in the content_security_policy block above
    # default-src 'self' https:;
    # media-src 'self' https: foo.com; <- inherited default src
    # worker-src foo.com <- overrode none
    @foos = Foo.all
  end

  def append_content_security_policy_directives(directives)
    directives.each do |directive, source_values|
      config = content_security_policy?.send(directive)
      if config.nil?
        config = []
        default_src = content_security_policy?.default_src
        config = default_src.dup
        content_security_policy?.default_src(*default_src)
      end
      config = [] if config == %w('none')
      content_security_policy?.send(directive, *(config + source_values))
    end
  end

  # GET /foos/1 or /foos/1.json
  def show
  end

  # GET /foos/new
  def new
    @foo = Foo.new
  end

  # GET /foos/1/edit
  def edit
  end

  # POST /foos or /foos.json
  def create
    @foo = Foo.new(foo_params)

    respond_to do |format|
      if @foo.save
        format.html { redirect_to @foo, notice: "Foo was successfully created." }
        format.json { render :show, status: :created, location: @foo }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @foo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /foos/1 or /foos/1.json
  def update
    respond_to do |format|
      if @foo.update(foo_params)
        format.html { redirect_to @foo, notice: "Foo was successfully updated." }
        format.json { render :show, status: :ok, location: @foo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @foo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /foos/1 or /foos/1.json
  def destroy
    @foo.destroy
    respond_to do |format|
      format.html { redirect_to foos_url, notice: "Foo was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_foo
      @foo = Foo.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def foo_params
      params.fetch(:foo, {})
    end
end
