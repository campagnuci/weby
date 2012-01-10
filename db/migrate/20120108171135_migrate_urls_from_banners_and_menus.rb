include Rails.application.routes.url_helpers

class MigrateUrlsFromBannersAndMenus < ActiveRecord::Migration
  # Cria url atravez da página cadastrada já que
  # anteriormente o campo era nil
  def self.up
    Banner.where(url: nil).each do |banner|
      next if banner.page_id == nil
      banner.url = url_for(
        controller: 'pages',
        action: 'show',
        site_id: banner.site.name,
        id: banner.page_id,
        only_path: true
      )
      banner.save!
    end

    Menu.where(link: nil).each do |menu|
      next if (menu.page_id == nil or menu.sites.first == nil)
      menu.link = url_for(
        controller: 'pages',
        action: 'show',
        site_id: menu.sites.first.name,
        id: menu.page_id,
        only_path: true
      )
      menu.save!
    end
  end

  def self.down
  end
end