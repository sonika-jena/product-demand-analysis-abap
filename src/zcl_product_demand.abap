CLASS zcl_product_demand DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS zcl_product_demand IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    out->write( '===== PRODUCT DEMAND ANALYSIS SYSTEM =====' ).

    " =========================
    " STEP 1: DATA GENERATION (RUN ONLY ONCE)
    " =========================

*   DATA: ls_db TYPE zprod_analysis.
*
*    DO 200 TIMES.
*
*      DATA: lv_cat TYPE string.
*      DATA: lv_sub TYPE string.
*
*      CASE sy-index MOD 7.
*
*        WHEN 0.
*          lv_cat = 'Electronics'.
*          CASE sy-index MOD 3.
*            WHEN 0. lv_sub = 'Mobile'.
*            WHEN 1. lv_sub = 'TV'.
*            WHEN 2. lv_sub = 'Camera'.
*          ENDCASE.
*
*        WHEN 1.
*          lv_cat = 'Computers'.
*          CASE sy-index MOD 3.
*            WHEN 0. lv_sub = 'Laptop'.
*            WHEN 1. lv_sub = 'Desktop'.
*            WHEN 2. lv_sub = 'Tablet'.
*          ENDCASE.
*
*        WHEN 2.
*          lv_cat = 'Accessories'.
*          CASE sy-index MOD 3.
*            WHEN 0. lv_sub = 'Mouse'.
*            WHEN 1. lv_sub = 'Keyboard'.
*            WHEN 2. lv_sub = 'Charger'.
*          ENDCASE.
*
*        WHEN 3.
*          lv_cat = 'Home Appliances'.
*          CASE sy-index MOD 3.
*            WHEN 0. lv_sub = 'AC'.
*            WHEN 1. lv_sub = 'Refrigerator'.
*            WHEN 2. lv_sub = 'Microwave'.
*          ENDCASE.
*
*        WHEN 4.
*          lv_cat = 'Gaming'.
*          CASE sy-index MOD 3.
*            WHEN 0. lv_sub = 'Console'.
*            WHEN 1. lv_sub = 'Controller'.
*            WHEN 2. lv_sub = 'Games'.
*          ENDCASE.
*
*        WHEN 5.
*          lv_cat = 'Office'.
*          CASE sy-index MOD 3.
*            WHEN 0. lv_sub = 'Printer'.
*            WHEN 1. lv_sub = 'Scanner'.
*            WHEN 2. lv_sub = 'Monitor'.
*          ENDCASE.
*
*        WHEN 6.
*          lv_cat = 'Wearables'.
*          CASE sy-index MOD 3.
*            WHEN 0. lv_sub = 'Smartwatch'.
*            WHEN 1. lv_sub = 'Earbuds'.
*            WHEN 2. lv_sub = 'Fitness Band'.
*          ENDCASE.
*
*      ENDCASE.
*
*      ls_db-client = sy-mandt.
*      ls_db-id     = sy-index.
*      ls_db-name   = |Product{ sy-index }|.
*      ls_db-category = lv_cat.
*      ls_db-subcat   = lv_sub.
*      ls_db-sales  = ( sy-index * 12 ) + ( sy-index MOD 9 * 5 ).
*      ls_db-stock  = ( sy-index * 7 ) - ( sy-index MOD 6 * 3 ) + 20.
*
*      INSERT zprod_analysis FROM @ls_db.
*
*    ENDDO.
*
*    COMMIT WORK.
*
*    out->write( 'Data inserted successfully' ).

    " =========================
    " STEP 2: FETCH DATA
    " =========================

    DATA: it_products TYPE TABLE OF zprod_analysis,
          ls_product  TYPE zprod_analysis.

    SELECT *
      FROM zprod_analysis
      INTO TABLE @it_products.

    " =========================
    " STEP 3: ANALYTICS
    " =========================

    TYPES: BEGIN OF ty_cat,
             category TYPE string,
             total    TYPE i,
             max_sale TYPE i,
             top_prod TYPE string,
             subcat   TYPE string,
           END OF ty_cat.

    DATA: it_cat TYPE STANDARD TABLE OF ty_cat,
          ls_cat TYPE ty_cat.

    DATA: lv_total   TYPE i VALUE 0,
          lv_max     TYPE i VALUE 0,
          lv_top     TYPE string,
          lv_restock TYPE i VALUE 0,
          lv_over    TYPE i VALUE 0,
          lv_normal  TYPE i VALUE 0.

    LOOP AT it_products INTO ls_product.

      lv_total = lv_total + ls_product-sales.

      IF ls_product-sales > lv_max.
        lv_max = ls_product-sales.
        lv_top = ls_product-name.
      ENDIF.

      " Inventory logic
      DATA(lv_avg) = ls_product-sales / 2.

      IF ls_product-stock < lv_avg.
        lv_restock += 1.
      ELSEIF ls_product-stock > lv_avg * 2.
        lv_over += 1.
      ELSE.
        lv_normal += 1.
      ENDIF.

      " Category aggregation
      READ TABLE it_cat INTO ls_cat WITH KEY category = ls_product-category.

      IF sy-subrc = 0.

        ls_cat-total = ls_cat-total + ls_product-sales.

        IF ls_product-sales > ls_cat-max_sale.
          ls_cat-max_sale = ls_product-sales.
          ls_cat-top_prod = ls_product-name.
          ls_cat-subcat   = ls_product-subcat.
        ENDIF.

        MODIFY it_cat FROM ls_cat INDEX sy-tabix.

      ELSE.

        ls_cat-category = ls_product-category.
        ls_cat-total    = ls_product-sales.
        ls_cat-max_sale = ls_product-sales.
        ls_cat-top_prod = ls_product-name.
        ls_cat-subcat   = ls_product-subcat.

        APPEND ls_cat TO it_cat.

      ENDIF.

    ENDLOOP.

    " =========================
    " OUTPUT
    " =========================

    out->write( '===== SUMMARY =====' ).
    out->write( |Total Sales: { lv_total }| ).
    out->write( |Top Product Overall: { lv_top }| ).
    out->write( |Max Sales Value: { lv_max }| ).

    out->write( '===== INVENTORY =====' ).
    out->write( |Restock: { lv_restock }| ).
    out->write( |Overstock: { lv_over }| ).
    out->write( |Normal: { lv_normal }| ).

    " Top 5
    DATA: lt_sorted TYPE TABLE OF zprod_analysis.
    lt_sorted = it_products.

    SORT lt_sorted BY sales DESCENDING.

    DATA(lv_rank) = 1.

    out->write( '===== TOP 5 PRODUCTS =====' ).

    LOOP AT lt_sorted INTO ls_product.

      IF lv_rank > 5.
        EXIT.
      ENDIF.

      out->write(
        |Rank { lv_rank } - { ls_product-name } ({ ls_product-category } / { ls_product-subcat }) Sales: { ls_product-sales }|
      ).

      lv_rank += 1.

    ENDLOOP.

    " Category analysis
    out->write( '===== CATEGORY ANALYSIS =====' ).

    LOOP AT it_cat INTO ls_cat.

      out->write( |Category: { ls_cat-category }| ).
      out->write( |Total: { ls_cat-total }| ).
      out->write( |Top Product: { ls_cat-top_prod }| ).
      out->write( |Subcategory: { ls_cat-subcat }| ).
      out->write( |Max Sales: { ls_cat-max_sale }| ).
      out->write( '----------------------' ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.