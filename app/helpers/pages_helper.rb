module PagesHelper
  # TODO verificação temporária para migração deve ser apagada após a migração
  def recreate_thumbs!(page)
    if File.file?(page.repository.archive.path) and 
      not File.file?(page.repository.archive.path(:little))
      page.repository.archive.reprocess!
    end
  end

  def link_to_cover_image(page)
  link_to image_tag("#{page.repository.archive.url(:mini)}",
                    :alt => page.repository.description),
                    site_page_path(@site, page, :type => params[:type]),
                    :title => page.repository.description
  end  
end