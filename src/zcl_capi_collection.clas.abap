CLASS zcl_capi_collection DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_capi_collection .
  PROTECTED SECTION.

    DATA:
      mt_collection TYPE STANDARD TABLE OF REF TO object .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_COLLECTION IMPLEMENTATION.


  METHOD zif_capi_collection~add.

    APPEND ir_object TO mt_collection.

  ENDMETHOD.


  METHOD zif_capi_collection~clear.

    CLEAR mt_collection.

  ENDMETHOD.


  METHOD zif_capi_collection~get_item.

    READ TABLE mt_collection INTO ro_object INDEX iv_index.

  ENDMETHOD.


  METHOD zif_capi_collection~get_iterator.

    DATA: lo_iterator TYPE REF TO zcl_capi_iterator.

    CREATE OBJECT lo_iterator
      EXPORTING
        ir_collection = me.

    ro_iterator = lo_iterator.

  ENDMETHOD.


  METHOD zif_capi_collection~is_empty.

    DATA: lv_lines TYPE i.

    lv_lines = lines( mt_collection ).
    IF lv_lines = 0.
      rv_empty = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD zif_capi_collection~remove.

    DELETE TABLE mt_collection FROM ir_item.

  ENDMETHOD.


  METHOD zif_capi_collection~remove_index.

    DELETE mt_collection INDEX iv_index.

  ENDMETHOD.


  METHOD zif_capi_collection~size.

    rv_size = lines( mt_collection ).

  ENDMETHOD.
ENDCLASS.
