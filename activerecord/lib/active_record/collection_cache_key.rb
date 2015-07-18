module ActiveRecord
  module CollectionCacheKey

    # Generates a cache key for the records in the given collection.
    # See <tt>ActiveRecord::Relation#cache_key</tt> for details.
    def collection_cache_key(collection = all, timestamp_column = :updated_at)
      query_signature = Digest::MD5.hexdigest(collection.to_sql)
      key = "#{collection.model_name.cache_key}/query-#{query_signature}-#{collection.size}"

      if timestamp = collection.maximum(timestamp_column)
        key = "#{key}-#{timestamp.utc.to_s(cache_timestamp_format)}"
      end

      key
    end
  end
end
