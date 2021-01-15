interface ZIF_CAPI_CALLABLE
  public .

  type-pools ABAP .

  methods CALL
    returning
      value(RO_RESULT) type ref to IF_SERIALIZABLE_OBJECT .
endinterface.
