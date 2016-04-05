# coding: utf-8

require 'nokogiri'
# modified from http://stackoverflow.com/questions/1230741/convert-a-nokogiri-document-to-a-ruby-hash/1231297#1231297

class Hash
  class << self
    def from_xml(xml_io)
      result = Nokogiri::XML( xml_io )

      { result.root.name.to_sym => xml_node_to_hash( result.root ) }
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def xml_node_to_hash( node )
      # If we are at the root of the document, start the hash
      return node.content.to_s unless node.element?

      result_hash = {}

      attributes = {}
      node.attributes.keys.each do |key|
        attributes[ node.attributes[ key ].name.to_sym ] = node.attributes[ key ].value
      end

      return attributes if node.children.empty?

      node.children.each do |child|
        result = xml_node_to_hash( child )

        if child.name == 'text'
          unless child.next_sibling || child.previous_sibling
            return result if attributes.empty?

            result_hash[ child.name.to_sym ] = result
          end
        else
          result_hash[ child.name.to_sym ] = [] unless result_hash[ child.name.to_sym ]
          result_hash[ child.name.to_sym ] = [ result_hash[ child.name.to_sym ] ] unless result_hash[ child.name.to_sym ].is_a?( Object::Array )

          result_hash[ child.name.to_sym ] << result
        end
      end

      # add code to remove non-data attributes e.g. xml schema, namespace here
      # if there is a collision then node content supersets attributes
      result_hash = attributes.merge( result_hash ) unless attributes.empty?

      result_hash
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
