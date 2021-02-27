
CLASS ltc_capi_executors DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS
.
*?﻿<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
*?<asx:values>
*?<TESTCLASS_OPTIONS>
*?<TEST_CLASS>ltc_Capi_Executors
*?</TEST_CLASS>
*?<TEST_MEMBER>f_Cut
*?</TEST_MEMBER>
*?<OBJECT_UNDER_TEST>ZCL_CAPI_EXECUTORS
*?</OBJECT_UNDER_TEST>
*?<OBJECT_IS_LOCAL/>
*?<GENERATE_FIXTURE>X
*?</GENERATE_FIXTURE>
*?<GENERATE_CLASS_FIXTURE/>
*?<GENERATE_INVOCATION>X
*?</GENERATE_INVOCATION>
*?<GENERATE_ASSERT_EQUAL>X
*?</GENERATE_ASSERT_EQUAL>
*?</TESTCLASS_OPTIONS>
*?</asx:values>
*?</asx:abap>
  PRIVATE SECTION.
    DATA:
      f_cut TYPE REF TO zcl_capi_executors.  "class under test

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
    DATA ro_capi_thread_pool_executor TYPE REF TO zcl_capi_thread_pool_executor.

    CREATE OBJECT lo_capi_message_handler.

    ro_capi_thread_pool_executor = zcl_capi_executors=>new_fixed_thread_pool(
        iv_server_group = 'parallel_generators'
        io_capi_message_handler = lo_capi_message_handler ).

    IF ro_capi_thread_pool_executor IS NOT BOUND.
      cl_aunit_assert=>fail( msg = 'Testing value ro_Capi_Thread_Pool_Executor' ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
