class ZCL_ITERATOR definition
  public
  create public .

public section.

  interfaces ZIF_ITERATOR .

  methods CONSTRUCTOR
    importing
      !IR_COLLECTION type ref to ZIF_COLLECTION .
protected section.
private section.

  data MR_COLLECTION type ref to ZIF_COLLECTION .
  data MV_INDEX type I value 0 ##NO_TEXT.
ENDCLASS.



CLASS ZCL_ITERATOR IMPLEMENTATION.


  method CONSTRUCTOR.

    mr_collection = ir_collection.

  endmethod.


  method ZIF_ITERATOR~CURRENT.

    ro_object = mr_collection->get_item( mv_index ).

  endmethod.


  method ZIF_ITERATOR~FIRST.

    mv_index = 1.
    ro_object = mr_collection->get_item( mv_index ).

  endmethod.


  method ZIF_ITERATOR~GET_INDEX.

    rv_index = mv_index.

  endmethod.


  method ZIF_ITERATOR~HAS_NEXT.

    IF mv_index < mr_collection->size( ).
      rv_hasnext = abap_true.
    ELSE.
      rv_hasnext = abap_false.
    ENDIF.

  endmethod.


  method ZIF_ITERATOR~LAST.

    mv_index = mr_collection->size( ).
    ro_object = mr_collection->get_item( mv_index ).

  endmethod.


  method ZIF_ITERATOR~NEXT.

    mv_index = mv_index + 1.
    ro_object = mr_collection->get_item( mv_index ).

  endmethod.
ENDCLASS.
