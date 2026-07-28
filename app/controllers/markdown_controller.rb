class MarkdownController < ApplicationController
  # Renders Markdown to sanitized HTML for the live description preview, using
  # the same helper as the task views so the preview matches the saved result.
  def preview
    render json: { html: helpers.render_markdown(params[:text].to_s) }
  end
end
