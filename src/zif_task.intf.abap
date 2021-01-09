interface ZIF_TASK
  public .

  interfaces ZIF_CALLABLE .
  interfaces IF_SERIALIZABLE_OBJECT .

  methods GET_NAME
    returning
      value(RV_NAME) type CHAR30 .
  methods GET_ID
    returning
      value(RV_ID) type GUID_32 .
endinterface.
