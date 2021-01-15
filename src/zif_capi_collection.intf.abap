interface ZIF_CAPI_COLLECTION
  public .

  type-pools ABAP .

  methods SIZE
    returning
      value(RV_SIZE) type I .
  methods IS_EMPTY
    returning
      value(RV_EMPTY) type BOOLE_D .
  methods GET_ITEM
    importing
      !IV_INDEX type I
    returning
      value(RO_OBJECT) type ref to OBJECT .
  methods ADD
    importing
      !IR_OBJECT type ref to OBJECT .
  methods REMOVE_INDEX
    importing
      !IV_INDEX type I .
  methods REMOVE
    importing
      !IR_ITEM type ref to OBJECT .
  methods CLEAR .
  methods GET_ITERATOR
    returning
      value(RO_ITERATOR) type ref to ZIF_CAPI_ITERATOR .
endinterface.
