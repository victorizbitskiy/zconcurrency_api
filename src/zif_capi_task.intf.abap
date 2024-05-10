interface ZIF_CAPI_TASK
  public .


  interfaces IF_SERIALIZABLE_OBJECT .
  interfaces ZIF_CAPI_CALLABLE .

  methods GET_NAME
    returning
      value(RV_RESULT) type STRING .
  methods GET_ID
    returning
      value(RV_RESULT) type GUID_32 .
  methods GET_OBJ_ID
    returning
      value(RV_RESULT) type CHAR50 .
endinterface.
