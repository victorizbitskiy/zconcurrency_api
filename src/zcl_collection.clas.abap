class ZCL_COLLECTION definition
  public
  create public .

public section.

  interfaces ZIF_COLLECTION .
protected section.

  data:
    mt_collection TYPE STANDARD TABLE OF REF TO object .
private section.
ENDCLASS.



CLASS ZCL_COLLECTION IMPLEMENTATION.


  method ZIF_COLLECTION~ADD.

    APPEND ir_object TO mt_collection.

  endmethod.


  method ZIF_COLLECTION~CLEAR.

    CLEAR mt_collection.

  endmethod.


  method ZIF_COLLECTION~GET_ITEM.

    READ TABLE mt_collection INTO ro_object INDEX iv_index.

  endmethod.


  method ZIF_COLLECTION~GET_ITERATOR.

    DATA: lo_iterator TYPE REF TO zcl_iterator.

    CREATE OBJECT lo_iterator
      EXPORTING
        ir_collection = me.

    rif_iterator = lo_iterator.

  endmethod.


  method ZIF_COLLECTION~IS_EMPTY.

    DATA: lv_lines TYPE i.

    lv_lines = LINES( mt_collection ).
    IF lv_lines = 0.
      rv_empty = abap_true.
    ENDIF.

  endmethod.


  method ZIF_COLLECTION~REMOVE.

    DELETE TABLE mt_collection FROM ir_item.

  endmethod.


  method ZIF_COLLECTION~REMOVE_INDEX.

    DELETE mt_collection INDEX iv_index.

  endmethod.


  method ZIF_COLLECTION~SIZE.

    rv_size = LINES( mt_collection ).

  endmethod.
ENDCLASS.
