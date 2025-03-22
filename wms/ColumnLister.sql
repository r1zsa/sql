SET SERVEROUTPUT ON;
DECLARE 
    v_sql CLOB;
    v_column_list VARCHAR2(32767);
    v_table_name VARCHAR2(100);
BEGIN
    v_column_list := '';
    /* Table name
        sku, sku_config, sku_sku_config, sku_tuc, supplier_sku, hazmat, sku_hazmat_reg
        inventory, inventory_transaction, inventory_transaction_archive, pick_face, move_task, location
        order_header, order_header_archive, order_line, order_line_archive, pre_advice_header, pre_advice_header_archive, pre_advice_line, pre_advice_line_archive, generation_shortage, shipping_manifest, shipping_manifest_archive
        sku_tuc_adt, supplier_sku_adt, location_adt, pick_face_adt
        scheduler_job, jobs, itl_extract_conf, system_alloc_task, lookup_table, condition_code, mqs_table_key, sku_mr, sku_allocation, pallet_config, order_mr, work_zone */
    v_table_name := 'shipping_manifest';
    v_table_name := UPPER(v_table_name);

    FOR rec IN (
        WITH user_def AS ( 
                    SELECT atc.table_name
                                            , atc.column_id, atc.column_name as "cc"
                                            , CASE
                                                    WHEN atc.column_name LIKE 'USER_DEF_%' THEN upper(user_defined_field.label)
                                                    ELSE atc.column_name
                                                END AS column_name
                                            , user_defined_field.label
                                                          FROM all_tab_columns atc
                                                          LEFT JOIN user_defined_field ON atc.column_name = user_defined_field.column_name AND
                                                          atc.table_name = user_defined_field.table_name
                                       WHERE 1 = 1 
                                            AND atc.table_name = v_table_name
                                           AND atc.owner = 'DCSDBA'
                                       ORDER BY atc.table_name
                                              , atc.column_id
                    )
                    SELECT
                          -- atc.table_name as "Table Name"
                         atc.column_name
                         , coalesce(language_text.text, 'No Description Found') AS column_description
                         --, atc.data_type as "Data Type"
                      --   , CASE WHEN atc.nullable = 'Y' THEN 'Yes' else 'No' END as "Nullable"
                    FROM all_tab_columns atc
                    INNER JOIN user_def ON atc.table_name = user_def.table_name AND atc.column_id = user_def.column_id
                    LEFT JOIN language_text ON lower(user_def.column_name) = language_text.label AND language_text.language LIKE 'EN_GB'
                    WHERE 1 = 1
                       AND atc.table_name = v_table_name
                       AND atc.owner = 'DCSDBA'
                    ORDER BY atc.table_name
                           , atc.column_id
    ) LOOP
        v_column_list := v_column_list || rec.column_name || ' AS "' || rec.column_description || '", ';
    END LOOP;

    v_column_list := RTRIM(v_column_list, ', ');
    v_sql := 'SELECT ' || CHR(10) || v_column_list || CHR(10) ||  'FROM ' || CHR(10) || v_table_name;
    DBMS_OUTPUT.PUT_LINE(v_sql);
    EXECUTE IMMEDIATE v_sql;
END;
/
