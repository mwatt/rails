module ActiveRecord
  module CollectionCacheKey

    # Generates a cache key for the records in the given collection.
    # See <tt>ActiveRecord::Relation#cache_key</tt> for details.
    def collection_cache_key(collection = all, timestamp_column = :updated_at)
      query_signature = Digest::MD5.hexdigest(collection.to_sql)
      key = "#{collection.model_name.cache_key}/query-#{query_signature}"

      size, timestamp = if collection.loaded?
        [collection.size, collection.collect(&timestamp_column).compact.max]
      else
        column_type = collection.klass.type_for_attribute(timestamp_column.to_s)
        column = "#{connection.quote_table_name(collection.table_name)}.#{connection.quote_column_name(timestamp_column)}"

        result = collection.select("COUNT(*) AS size", "MAX(#{column}) AS timestamp").to_a.first
        [result.size, column_type.deserialize(result.timestamp)]
      end

      if timestamp
        "#{key}-#{size}-#{timestamp.utc.to_s(cache_timestamp_format)}"
      else
        "#{key}-#{size}"
      end
    end
  end
end
