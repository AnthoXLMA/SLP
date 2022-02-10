# frozen_string_literal: true

module ApplicationHelper
  CGU_FR_URL = 'https://docs.google.com/document/d/e/2PACX-1vTzaUlHFJI2YUZtmKUaTuHhsqmkyVMRtFXfap6j9HgXVr95mmTw3Y75zCJxgEjCDg/pub'
  CGU_EN_URL = 'https://docs.google.com/document/d/e/2PACX-1vRPtuH3cCkBDdAVjd-YUxFjccC8F8MkhuFsnjtEQxOItONE5gBxfGHMjEQdzcF9Ag/pub'
  
  def request_path(locale)
    request.env['REQUEST_PATH']&.sub(%r{^(/)(en|fr)?(/)?}, "\\1#{locale}/")
  end

  def cgu_url
    return CGU_FR_URL if I18n.locale&.to_sym == :fr

    CGU_EN_URL
  end

  def tour_image(tour, size, args = {})
    use = args.delete(:use)
    if tour.image.attached?
      image_tag tour.image.variant(resize_to_fill: size), args
    elsif use == :text
      content_tag(:span, t('application.no_image_uploaded'))
    else
      image_pack_tag 'default_tour_norm.webp', **args
    end
  end

  def tour_thumbnail(tour, size, args = {})
    use = args.delete(:use)
    if tour.thumbnail.attached?
      image_tag tour.thumbnail.variant(resize_to_fill: size), **args
    elsif use == :text
      content_tag(:span, t('application.no_thumbnail_uploaded'))
    else
      image_pack_tag 'default_tour_small.webp', **args
    end
  end

  def guide_image(guide, size, args = {})
    use = args.delete(:use)
    if guide.image.attached?
      image_tag guide.image.variant(resize_to_fill: size), args
    elsif use == :text
      content_tag(:span, t('application.no_image_uploaded'))
    elsif guide.user.man?
      image_pack_tag 'avatar_tom.webp', **args
    else
      image_pack_tag 'avatar_nan.webp', **args
    end
  end
end
