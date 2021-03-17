
CLASS ltc_capi_executors DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA:
      mo_cut TYPE REF TO zcl_capi_executors.  "class under test

    METHODS: setup.
    METHODS: teardown.
    METHODS: new_fixed_thread_pool FOR TESTING.
ENDCLASS.       "ltc_Capi_Executors


CLASS ltc_capi_executors IMPLEMENTATION.

  METHOD setup.

  ENDMETHOD.


  METHOD teardown.

  ENDMETHOD.


  METHOD new_fixed_thread_pool.

    DATA lo_capi_message_handler TYPE REF TO zcl_capi_message_handler.
    DATA lo_capi_thread_pool_executor TYPE REF TO zcl_capi_thread_pool_executor.

    CREATE OBJECT lo_capi_message_handler.

    lo_capi_thread_pool_executor = zcl_capi_executors=>new_fixed_thread_pool( 
      iv_server_group = 'parallel_generators'
      io_capi_message_handler = lo_capi_message_handler ).

    IF lo_capi_thread_pool_executor IS NOT BOUND.
      cl_aunit_assert=>fail( msg = 'Testing value lo_Capi_Thread_Pool_Executor' ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
