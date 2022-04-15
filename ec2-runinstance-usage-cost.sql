SELECT bill_invoice_id,
    line_item_usage_account_id,
    line_item_line_item_type,
    product_region,
    product_availability_zone,
    product_instance_type_family,
    product_instance_type,
    EC2_COST_TYPE,
    line_item_usage_type,
    resource_tags_user_project,
    SUM(EC2_RUN_INSTANCE_HOURS) AS SUM_EC2_RUN_INSTANCE_HOURS,
    SUM(EC2_RUN_INSTANCE_GROSS_COST) AS SUM_EC2_RUN_INSTANCE_GROSS_COST,
    SUM(EC2_RUN_INSTANCE_NET_COST) AS SUM_EC2_RUN_INSTANCE_NET_COST
FROM (
        SELECT bill_invoice_id,
            line_item_usage_account_id,
            line_item_line_item_type,
            product_region,
            product_availability_zone,
            product_instance_type_family,
            product_instance_type,
            CASE
                WHEN POSITION('BoxUsage' IN line_item_usage_type) > 0
                AND POSITION('DiscountedUsage' IN line_item_line_item_type) > 0 THEN 'RI'
                WHEN POSITION('BoxUsage' IN line_item_usage_type) > 0
                AND POSITION(
                    'SavingsPlanCoveredUsage' IN line_item_line_item_type
                ) > 0 THEN 'SavingsPlan'
                WHEN POSITION('BoxUsage' IN line_item_usage_type) > 0
                AND POSITION(
                    'SavingsPlanNegation' IN line_item_line_item_type
                ) > 0 THEN 'SavingsPlan'
                WHEN POSITION('DedicatedUsage' IN line_item_usage_type) > 0 THEN 'DedicatedHost'
                WHEN POSITION('SpotUsage' IN line_item_usage_type) > 0 THEN 'Spot'
                WHEN POSITION('ReservedHostUsage' IN line_item_usage_type) > 0 THEN 'ReservedHost'
                WHEN POSITION('UnusedBox' IN line_item_usage_type) > 0 THEN 'Unused'
                WHEN POSITION('BoxUsage' IN line_item_usage_type) > 0
                AND POSITION('Usage' IN line_item_line_item_type) > 0 THEN 'OD'
                ELSE 'FIXME'
            END AS EC2_COST_TYPE,
            line_item_usage_type,
            resource_tags_user_project,
            CASE
                WHEN POSITION(
                    'SavingsPlanNegation' IN line_item_line_item_type
                ) > 0 THEN 0
                ELSE line_item_usage_amount
            END AS EC2_RUN_INSTANCE_HOURS,
            CASE
                WHEN POSITION('DiscountedUsage' IN line_item_line_item_type) > 0 THEN reservation_effective_cost
                WHEN POSITION(
                    'SavingsPlanCoveredUsage' IN line_item_line_item_type
                ) > 0 THEN savings_plan_savings_plan_effective_cost
                WHEN POSITION(
                    'SavingsPlanNegation' IN line_item_line_item_type
                ) > 0 THEN 0
                WHEN POSITION(
                    'EdpDiscount' IN line_item_line_item_type
                ) > 0 THEN 0
                WHEN POSITION('Usage' IN line_item_line_item_type) > 0 THEN line_item_unblended_cost
                ELSE 999999
            END AS EC2_RUN_INSTANCE_GROSS_COST,
            CASE
                WHEN POSITION('DiscountedUsage' IN line_item_line_item_type) > 0 THEN reservation_net_effective_cost
                WHEN POSITION(
                    'SavingsPlanCoveredUsage' IN line_item_line_item_type
                ) > 0 THEN savings_plan_net_savings_plan_effective_cost
                WHEN POSITION(
                    'SavingsPlanNegation' IN line_item_line_item_type
                ) > 0 THEN 0
                WHEN POSITION(
                    'EdpDiscount' IN line_item_line_item_type
                ) > 0 THEN 0
                WHEN POSITION('Usage' IN line_item_line_item_type) > 0 THEN line_item_net_unblended_cost
                ELSE 999999
            END AS EC2_RUN_INSTANCE_NET_COST
        FROM <table>
        WHERE line_item_product_code = 'AmazonEC2'
            AND (
                line_item_usage_type LIKE '%BoxUsage%'
                OR line_item_usage_type LIKE '%DedicatedUsage%'
                OR line_item_usage_type LIKE '%SpotUsage%'
                OR line_item_usage_type LIKE '%HighUsage%'
                OR line_item_usage_type LIKE '%SchedUsage%'
                OR line_item_usage_type LIKE '%HostUsage%'
                OR line_item_usage_type LIKE '%HostBoxUsage%'
                OR line_item_usage_type LIKE '%ReservedHostUsage%'
                OR line_item_usage_type LIKE '%UnusedBox%'
            )
            AND line_item_line_item_type != 'Tax'
            AND line_item_line_item_type != 'EdpDiscount'
    )
GROUP BY 1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10