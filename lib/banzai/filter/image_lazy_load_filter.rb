module Banzai
  module Filter
    # HTML filter that moves the value of the src attribute to the data-src attribute so it can be lazy loaded
    class ImageLazyLoadFilter < HTML::Pipeline::Filter
      def call
        doc.xpath('descendant-or-self::img').each do |img|
          img['class'] ||= '' << 'lazy'
          img['data-src'] = img['src']
          img['src'] = LazyImageTagHelper.placeholder_image
        end

        doc
      end
    end
  end
end
