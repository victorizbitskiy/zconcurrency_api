interface ZIF_CAPI_EXECUTOR_SERVICE
  public .


  methods INVOKE_ALL
    importing
      !IO_TASKS type ref to ZIF_CAPI_COLLECTION
    returning
      value(RO_RESULTS) type ref to ZIF_CAPI_COLLECTION .
endinterface.
