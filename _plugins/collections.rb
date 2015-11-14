module Jekyll
  class SpicyCollections < Generator
    VERSION = '0.0.2'
    safe true
    priority :high

    def generate(site)
      @lookup = Hash.new(0)
      site.collections.each do |name, collection|
        Jekyll.logger.info "found metadata for collection #{name}: #{collection.metadata}"
        assign_navigation_links collection
        create_hash site, name, collection
      end
      site.config['lookup'] = @lookup
    end

    def idname_for(collection)
      collection.metadata.fetch 'id'
    end

    def assign_navigation_links(collection)
      sorted_collection(collection).each_cons(2) do |d1, d2|
        d2.data['previous'] = d1
        d1.data['next']     = d2
        end
    end

    def create_hash(site, name, collection)
      @lookup[name] = Hash.new(0)
      Jekyll.logger.info "Creating lookup hash for #{name}"
      collection.docs.each() do |d|
        @lookup[name][d.data[idname_for(collection)]] = d
      end
    end

    def sorted_collection(collection)
      sort_field = collection.metadata.fetch 'sort_by', 'date'
      collection_sorted_by_field(collection, sort_field)
    end

    def collection_sorted_by_field(collection, field)
      if collection.docs.all? { |d| !!d.data[field] }
        Jekyll.logger.info "sorting by data field: #{field}"
        collection.docs.sort_by { |d| d.data.fetch(field) }
      else
        Jekyll.logger.info "sorting by object field: #{field}"
        collection.docs.sort_by(&:"#{field}")
      end
    end
  end
end
