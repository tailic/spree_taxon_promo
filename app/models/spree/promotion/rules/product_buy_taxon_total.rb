module Spree
  class Promotion::Rules::ProductBuyTaxonTotal < PromotionRule

    preference :amount, :decimal, default: 1000.00
    preference :taxon, :string, :default => ''
    preference :operator, :string, default: '>'

    OPERATORS = ['gt', 'gte']

    def applicable?(promotable)
      promotable.is_a?(Spree::Order)
    end

    def eligible?(order, options = {})
      item_total = 0.0
      order.line_items.each do |line_item|
        matched = false
        preferred_taxons.each do |tx|
          matched = true if line_item.product.taxons.where(:name => tx).present?
        end
        item_total += line_item.amount if matched
      end
      item_total.send(preferred_operator == 'gte' ? :>= : :>, BigDecimal.new(preferred_amount.to_s))
    end

    def actionable?(line_item)
      preferred_taxons.each do |tx|
        return true if line_item.product.taxons.where(:name => tx).present?
      end
      false
    end

    def preferred_taxons
      preferred_taxon.split(',').map(&:strip)
    end

    private

      def formatted_amount_min
        Spree::Money.new(preferred_amount_min).to_s
      end

      def formatted_amount_max
        Spree::Money.new(preferred_amount_max).to_s
      end

      def ineligible_message_max
        if preferred_operator_max == 'gte'
          eligibility_error_message(:item_total_more_than_or_equal, amount: formatted_amount_max)
        else
          eligibility_error_message(:item_total_more_than, amount: formatted_amount_max)
        end
      end

      def ineligible_message_min
        if preferred_operator_min == 'gte'
          eligibility_error_message(:item_total_less_than, amount: formatted_amount_min)
        else
          eligibility_error_message(:item_total_less_than_or_equal, amount: formatted_amount_min)
        end
      end

  end
end
