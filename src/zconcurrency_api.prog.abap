*&---------------------------------------------------------------------*
*& Report ZCONCURRENCY_API
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zconcurrency_api.

TYPE-POOLS: spta.

*&---------------------------------------------------------------------*
*&      Form  before_rfc
*&---------------------------------------------------------------------*
FORM before_rfc USING is_before_rfc_imp TYPE spta_t_before_rfc_imp
             CHANGING cs_before_rfc_exp TYPE spta_t_before_rfc_exp
                      ct_rfcdata TYPE spta_t_indxtab
                      ct_failed_objects TYPE spta_t_failed_objects
                      ct_objects_in_process TYPE spta_t_objects_in_process
                      co_capi_spta_gateway TYPE REF TO zcl_capi_spta_gateway.

  STATICS: lo_tasks_iterator  TYPE REF TO zif_capi_iterator.
  DATA: lo_task               TYPE REF TO zif_capi_task,
        lv_task               TYPE xstring,
        ls_objects_in_process LIKE LINE OF ct_objects_in_process.

  IF ct_failed_objects[] IS NOT INITIAL.
    PERFORM process_failed_objects CHANGING cs_before_rfc_exp
                                            ct_rfcdata[]
                                            ct_failed_objects[]
                                            ct_objects_in_process[]
                                            co_capi_spta_gateway.
    RETURN.
  ENDIF.

  IF lo_tasks_iterator IS NOT BOUND.
    lo_tasks_iterator = co_capi_spta_gateway->mo_tasks->get_iterator( ).
  ENDIF.

  IF lo_tasks_iterator->has_next( ) = abap_true.

    lo_task ?= lo_tasks_iterator->next( ).
    lv_task = zcl_capi_spta_gateway=>serialize_task( lo_task ).

    CALL FUNCTION 'SPTA_INDX_PACKAGE_ENCODE'
      EXPORTING
        data    = lv_task
      IMPORTING
        indxtab = ct_rfcdata.

    ls_objects_in_process-obj_id = lo_task->get_id( ).
    APPEND ls_objects_in_process TO ct_objects_in_process[].

    cs_before_rfc_exp-start_rfc = abap_true.
  ELSE.
    cs_before_rfc_exp-start_rfc = space.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  in_rfc
*&---------------------------------------------------------------------*
FORM in_rfc USING is_in_rfc_imp TYPE spta_t_in_rfc_imp
         CHANGING cs_in_rfc_exp TYPE spta_t_in_rfc_exp
                  ct_rfcdata TYPE spta_t_indxtab.

  DATA: lv_task   TYPE xstring,
        lo_task   TYPE REF TO zif_capi_task,
        lo_result TYPE REF TO if_serializable_object,
        lv_result TYPE xstring.

  SET UPDATE TASK LOCAL.

  CALL FUNCTION 'SPTA_INDX_PACKAGE_DECODE'
    EXPORTING
      indxtab = ct_rfcdata
    IMPORTING
      data    = lv_task.

  lo_task = zcl_capi_spta_gateway=>deserialize_task( lv_task ).
  lo_result = lo_task->zif_capi_callable~call( ).
  lv_result = zcl_capi_spta_gateway=>serialize_result( lo_result ).

  CALL FUNCTION 'SPTA_INDX_PACKAGE_ENCODE'
    EXPORTING
      data    = lv_result
    IMPORTING
      indxtab = ct_rfcdata.

  COMMIT WORK.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  after_rfc
*&---------------------------------------------------------------------*
FORM after_rfc USING it_rfcdata TYPE spta_t_indxtab
                     iv_rfcsubrc TYPE sy-subrc
                     iv_rfcmsg TYPE spta_t_rfcmsg
                     it_objects_in_process TYPE spta_t_objects_in_process
                     is_after_rfc_imp TYPE spta_t_after_rfc_imp
            CHANGING cs_after_rfc_exp TYPE spta_t_after_rfc_exp
                     co_capi_spta_gateway TYPE REF TO zcl_capi_spta_gateway.

  CONSTANTS: lc_max_task_crash TYPE i VALUE 1.

  DATA: lv_result             TYPE xstring,
        lo_result             TYPE REF TO object,
        ls_objects_in_process LIKE LINE OF it_objects_in_process,
        lv_task_id            TYPE guid_32,
        lv_tc_size            TYPE i,
        lv_rc_size            TYPE i.

  IF iv_rfcsubrc IS INITIAL.
*   Task completed successfully

    CALL FUNCTION 'SPTA_INDX_PACKAGE_DECODE'
      EXPORTING
        indxtab = it_rfcdata
      IMPORTING
        data    = lv_result.

    lo_result = zcl_capi_spta_gateway=>deserialize_result( lv_result ).
    co_capi_spta_gateway->mo_results->add( lo_result ).

    lv_tc_size = co_capi_spta_gateway->mo_tasks->size( ).
    lv_rc_size = co_capi_spta_gateway->mo_results->size( ).

    cl_progress_indicator=>progress_indicate( i_text = '&1% (&2 of &3) of the tasks processed'(001)
                                              i_processed = lv_rc_size
                                              i_total = lv_tc_size
                                              i_output_immediately = abap_true ).

  ELSE.

    READ TABLE it_objects_in_process INTO ls_objects_in_process INDEX 1.
    IF sy-subrc = 0.
      lv_task_id = ls_objects_in_process-obj_id.
      co_capi_spta_gateway->mo_capi_message_handler->add_message( iv_task_id = lv_task_id
                                                                  iv_task_name = ''
                                                                  iv_rfcsubrc = iv_rfcsubrc
                                                                  iv_rfcmsg = iv_rfcmsg ).

      IF ls_objects_in_process-fail_count = lc_max_task_crash.
*       If the task has already crashed, and now it has crashed a second time,
*       we will not restart it
        cs_after_rfc_exp-no_resubmission_on_error = abap_true.
      ELSE.
        cs_after_rfc_exp-no_resubmission_on_error = co_capi_spta_gateway->mv_no_resubmission_on_error.
      ENDIF.

    ENDIF.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  process_failed_objects
*&---------------------------------------------------------------------*
FORM process_failed_objects CHANGING cs_before_rfc_exp TYPE spta_t_before_rfc_exp
                                     ct_rfcdata TYPE spta_t_indxtab
                                     ct_failed_objects TYPE spta_t_failed_objects
                                     ct_objects_in_process TYPE spta_t_objects_in_process
                                     co_capi_spta_gateway TYPE REF TO zcl_capi_spta_gateway.

  DATA: lo_tasks_iterator     TYPE REF TO zif_capi_iterator,
        lo_task               TYPE REF TO zif_capi_task,
        lv_task               TYPE xstring,
        ls_objects_in_process LIKE LINE OF ct_objects_in_process.

  FIELD-SYMBOLS: <ls_failed_objects> LIKE LINE OF ct_failed_objects.

  READ TABLE ct_failed_objects ASSIGNING <ls_failed_objects> INDEX 1.
  IF <ls_failed_objects> IS ASSIGNED.

    lo_tasks_iterator = co_capi_spta_gateway->mo_tasks->get_iterator( ).

    WHILE lo_tasks_iterator->has_next( ) = abap_true.
      lo_task ?= lo_tasks_iterator->next( ).

      IF lo_task->get_id( ) = <ls_failed_objects>-obj_id.

        lv_task = zcl_capi_spta_gateway=>serialize_task( lo_task ).

        CALL FUNCTION 'SPTA_INDX_PACKAGE_ENCODE'
          EXPORTING
            data    = lv_task
          IMPORTING
            indxtab = ct_rfcdata.

        ls_objects_in_process-obj_id = <ls_failed_objects>-obj_id.
        ls_objects_in_process-fail_count = <ls_failed_objects>-fail_count + 1.
        ls_objects_in_process-last_error = <ls_failed_objects>-last_error.

        APPEND ls_objects_in_process TO ct_objects_in_process[].

        CLEAR: ct_failed_objects[], ct_failed_objects.
        cs_before_rfc_exp-start_rfc = abap_true.
        EXIT.
      ENDIF.

    ENDWHILE.

  ENDIF.

ENDFORM.
