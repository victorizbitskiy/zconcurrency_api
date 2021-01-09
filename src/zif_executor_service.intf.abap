interface ZIF_EXECUTOR_SERVICE
  public .


  methods INVOKE_ALL
    importing
      !IO_TASKS type ref to ZCL_COLLECTION
    returning
      value(RO_RESULTS) type ref to ZIF_COLLECTION .
endinterface.
