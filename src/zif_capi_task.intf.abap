interface ZIF_CAPI_TASK
  public .

  type-pools ABAP .

  interfaces IF_SERIALIZABLE_OBJECT .
  interfaces ZIF_CAPI_CALLABLE .

  methods GET_NAME
    returning
      value(RV_NAME) type CHAR30 .
  methods GET_ID
    returning
      value(RV_ID) type GUID_32 .
endinterface.
