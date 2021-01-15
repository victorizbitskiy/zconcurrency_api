interface ZIF_CAPI_ITERATOR
  public .

  type-pools ABAP .

  methods GET_INDEX
    returning
      value(RV_INDEX) type I .
  methods HAS_NEXT
    returning
      value(RV_HASNEXT) type BOOLE_D .
  methods NEXT
    returning
      value(RO_OBJECT) type ref to OBJECT .
  methods FIRST
    returning
      value(RO_OBJECT) type ref to OBJECT .
  methods LAST
    returning
      value(RO_OBJECT) type ref to OBJECT .
  methods CURRENT
    returning
      value(RO_OBJECT) type ref to OBJECT .
endinterface.
