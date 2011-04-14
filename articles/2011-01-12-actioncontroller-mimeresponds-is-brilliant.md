title: ActionController::MimeResponds is brilliant
slug: actioncontroller-mimeresponds-is-brilliant


Was a little bit blown away yesterday, by how smart the ActionController::MimeResponds
module in Rails ActionPack really is. For the longest time when using `respond_with`
(the younger sibling of `respond_to`,) I've been doing it wrong.~


I've written code similar to this whenever I've needed to override the default behavior:

    respond_to :html, :json

    # .. other actions omitted for brevity

    def create
      @discussion = Discussion.find(params[:discussion_id])
      @entry = @discussion.entries.create(params[:entry])

      respond_with @entry do |format|
        format.html do
          if @entry.new_record?
            render 'discussions/show'
          else
            redirect_to discussion_url(@discussion)
          end
        end
        format.json { render :json => @entry }
      end
    end

My assumption was that if I needed to change the default behavior, I had to more or less
mimic the behavior of `respond_to` (not to be confused with the `respond_to` as seen in
the example above) which is to explicitly define behavior for each MIME type response.
Well, it turns out that you only need to override that which deviates from the default
behavior and the rest will still be handled as per the default. The `respond_with` block
in the previous example can be simplified as follows:

    respond_with @entry, :location => discussion_url(@discussion) do |format|
      if @entry.new_record?
        format.html { render 'discussions/show' }
      end
    end

The only thing that deviates from the standard behavior, is the fact I want to render a
template belonging to another controller and action (the one that initiated the HTTP POST)
whenever the new entry wasn't successfully created. The assumption being it most likely
failed validation, and we need to present the validation errors to the user.

Why `respond_with` hasn't been better documented in e.g. [The Ruby on Rails Guides](http://guides.rubyonrails.org/)
or in [the API documentation](http://rubydoc.info/docs/rails/3.0.0/ActionController/MimeResponds)
is not known to me, but my best guess would be because this is a new feature in Rails 3,
nobody has gotten around to it yet.
I only found out about this behavior by looking at the [source code](https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/metal/mime_responds.rb),
but for all I know this might be common knowledge and I've simply overlooked it somehow.