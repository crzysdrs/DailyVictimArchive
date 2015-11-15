module Jekyll
  module AssetFilter
    def article_cleanup(input, baseurl, lookup)
      #Jekyll.logger.info lookup
      input.gsub(/%ARTICLE\[([0-9]+)\]%/) {
        |m| baseurl + lookup["#{$1}".to_i].url
      }.gsub(/(src|href)="(img\/[^"]+)"/) {
        |m| "#{$1}=\"#{baseurl}#{$2}\""
      }.gsub(/(src|href)="\.\/"/) {
        |m| "(#{$1}=\"#{baseurl}#\""
      }
    end

    def remove_p(input)
      input = input.gsub(/(<p>|<\/p>)/m) { |m| "" }
      input = input.gsub(/\n+$/m) { |m| "" }
    end
  end
end

Liquid::Template.register_filter(Jekyll::AssetFilter)
