CLASS zcl_product_demand DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS zcl_product_demand IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    out->write( 'Product Demand Analysis System' ).

    " ========================
    " STRUCTURES
    " ========================
    TYPES: BEGIN OF ty_product,
             id       TYPE string,
             name     TYPE string,
             category TYPE string,
             subcat   TYPE string,
             sales    TYPE i,
             stock    TYPE i,
           END OF ty_product.

    TYPES: BEGIN OF ty_cat,
             category TYPE string,
             total    TYPE i,
             max_sale TYPE i,
             top_prod TYPE string,
             subcat   TYPE string,
           END OF ty_cat.

    DATA: it_products TYPE STANDARD TABLE OF ty_product,
          lt_sorted   TYPE STANDARD TABLE OF ty_product,
          it_cat      TYPE STANDARD TABLE OF ty_cat,
          ls_cat      TYPE ty_cat,
          ls_product  TYPE ty_product,
          lv_cat      TYPE string,
          lv_sub      TYPE string.

    " ========================
    " DATA GENERATION
    " ========================
    DO 200 TIMES.

      CASE sy-index MOD 7.

        WHEN 0.
          lv_cat = 'Electronics'.
          CASE sy-index MOD 3.
            WHEN 0. lv_sub = 'Mobile'.
            WHEN 1. lv_sub = 'TV'.
            WHEN 2. lv_sub = 'Camera'.
          ENDCASE.

        WHEN 1.
          lv_cat = 'Computers'.
          CASE sy-index MOD 3.
            WHEN 0. lv_sub = 'Laptop'.
            WHEN 1. lv_sub = 'Desktop'.
            WHEN 2. lv_sub = 'Tablet'.
          ENDCASE.

        WHEN 2.
          lv_cat = 'Accessories'.
          CASE sy-index MOD 3.
            WHEN 0. lv_sub = 'Mouse'.
            WHEN 1. lv_sub = 'Keyboard'.
            WHEN 2. lv_sub = 'Charger'.
          ENDCASE.

        WHEN 3.
          lv_cat = 'Home Appliances'.
          CASE sy-index MOD 3.
            WHEN 0. lv_sub = 'AC'.
            WHEN 1. lv_sub = 'Refrigerator'.
            WHEN 2. lv_sub = 'Microwave'.
          ENDCASE.

        WHEN 4.
          lv_cat = 'Gaming'.
          CASE sy-index MOD 3.
            WHEN 0. lv_sub = 'Console'.
            WHEN 1. lv_sub = 'Controller'.
            WHEN 2. lv_sub = 'Games'.
          ENDCASE.

        WHEN 5.
          lv_cat = 'Office'.
          CASE sy-index MOD 3.
            WHEN 0. lv_sub = 'Printer'.
            WHEN 1. lv_sub = 'Scanner'.
            WHEN 2. lv_sub = 'Monitor'.
          ENDCASE.

        WHEN 6.
          lv_cat = 'Wearables'.
          CASE sy-index MOD 3.
            WHEN 0. lv_sub = 'Smartwatch'.
            WHEN 1. lv_sub = 'Earbuds'.
            WHEN 2. lv_sub = 'Fitness Band'.
          ENDCASE.

      ENDCASE.

      APPEND VALUE #(
        id       = |P{ sy-index }|
        name     = |Product{ sy-index }|
        category = lv_cat
        subcat   = lv_sub
        sales    = ( sy-index * 12 ) + ( sy-index MOD 9 * 5 )
        stock    = ( sy-index * 7 ) - ( sy-index MOD 6 * 3 ) + 20
      ) TO it_products.

    ENDDO.

    " ========================
    " ANALYTICS
    " ========================
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

      " Inventory Logic
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

    " ========================
    " SUMMARY
    " ========================
    out->write( '===== SUMMARY =====' ).
    out->write( |Total Sales : { lv_total }| ).
    out->write( '===================================' ).

    out->write( '===== INVENTORY STATUS =====' ).
    out->write( |Restock Required : { lv_restock }| ).
    out->write( |Overstock        : { lv_over }| ).
    out->write( |Normal           : { lv_normal }| ).
    out->write( '===================================' ).

    " ========================
    " TOP 5 PRODUCTS
    " ========================
    lt_sorted = it_products.
    SORT lt_sorted BY sales DESCENDING.

    DATA(lv_rank) = 1.

    out->write( '===== TOP 5 PRODUCTS =====' ).

    LOOP AT lt_sorted INTO ls_product.

      IF lv_rank > 5.
        EXIT.
      ENDIF.

      out->write(
        |Rank { lv_rank } | &&
        | Product: { ls_product-name } | &&
        | Category: { ls_product-category } | &&
        | Subcategory: { ls_product-subcat } | &&
        | Sales: { ls_product-sales }|
      ).

      lv_rank += 1.

    ENDLOOP.
    out->write( '===================================' ).

    " ========================
    " CATEGORY ANALYSIS
    " ========================
    out->write( '===== CATEGORY ANALYSIS =====' ).

    LOOP AT it_cat INTO ls_cat.

      out->write( |Category      : { ls_cat-category }| ).
      out->write( |Total Sales   : { ls_cat-total }| ).
      out->write( |Top Product   : { ls_cat-top_prod }| ).
      out->write( |Subcategory   : { ls_cat-subcat }| ).
      out->write( |Max Sales     : { ls_cat-max_sale }| ).
      out->write( '------------------------------' ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.