*&---------------------------------------------------------------------*
*& Report ZCONCURRENCY_API
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZCONCURRENCY_API.

*&---------------------------------------------------------------------*
*&      Form  before_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM before_rfc USING is_before_rfc_imp TYPE spta_t_before_rfc_imp
             CHANGING cs_before_rfc_exp TYPE spta_t_before_rfc_exp
                      ct_rfcdata TYPE spta_t_indxtab
                      ct_failed_objects TYPE spta_t_failed_objects
                      ct_objects_in_process TYPE spta_t_objects_in_process
                      co_spta_gateway TYPE REF TO zcl_spta_gateway.

  STATICS: lo_tasks_iterator TYPE REF TO zif_iterator.
  DATA: lo_task TYPE REF TO zcl_abstract_task,
        lv_task TYPE xstring,
        ls_objects_in_process LIKE LINE OF ct_objects_in_process.

  IF ct_failed_objects[] IS NOT INITIAL.
    PERFORM process_failed_objects CHANGING cs_before_rfc_exp
                                            ct_rfcdata[]
                                            ct_failed_objects[]
                                            ct_objects_in_process[]
                                            co_spta_gateway.
    RETURN.
  ENDIF.

  IF lo_tasks_iterator IS NOT BOUND.
    lo_tasks_iterator = co_spta_gateway->mo_tasks->get_iterator( ).
  ENDIF.

  IF lo_tasks_iterator->has_next( ) = abap_true.

    lo_task ?= lo_tasks_iterator->next( ).
    lv_task = zcl_spta_wrapper=>serialize( lo_task ).

    CALL FUNCTION 'SPTA_INDX_PACKAGE_ENCODE'
      EXPORTING
        data    = lv_task
      IMPORTING
        indxtab = ct_rfcdata.

    ls_objects_in_process-obj_id = lo_task->zif_task~get_id( ).
    APPEND ls_objects_in_process TO ct_objects_in_process[].

    cs_before_rfc_exp-start_rfc = abap_true.
  ELSE.
    cs_before_rfc_exp-start_rfc = space.
  ENDIF.

ENDFORM.                    "before_rfc

*&---------------------------------------------------------------------*
*&      Form  in_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM in_rfc USING is_in_rfc_imp TYPE spta_t_in_rfc_imp
         CHANGING cs_in_rfc_exp TYPE spta_t_in_rfc_exp
                  ct_rfcdata TYPE spta_t_indxtab.

  DATA: lv_task TYPE xstring,
        lo_task TYPE REF TO zcl_abstract_task,
        lo_result TYPE REF TO if_serializable_object,
        lv_result TYPE xstring.

  CALL FUNCTION 'SPTA_INDX_PACKAGE_DECODE'
    EXPORTING
      indxtab = ct_rfcdata
    IMPORTING
      data    = lv_task.

  lo_task = zcl_spta_wrapper=>deserialize( lv_task ).
  lo_result = lo_task->zif_callable~call( ).

  CALL TRANSFORMATION id_indent
  SOURCE obj = lo_result
  RESULT XML lv_result.

  CALL FUNCTION 'SPTA_INDX_PACKAGE_ENCODE'
    EXPORTING
      data    = lv_result
    IMPORTING
      indxtab = ct_rfcdata.

ENDFORM.                    "in_rfc

*&---------------------------------------------------------------------*
*&      Form  after_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM after_rfc USING it_rfcdata TYPE spta_t_indxtab
                     iv_rfcsubrc TYPE sy-subrc
                     iv_rfcmsg TYPE spta_t_rfcmsg
                     it_objects_in_process TYPE spta_t_objects_in_process
                     is_after_rfc_imp TYPE spta_t_after_rfc_imp
            CHANGING cs_after_rfc_exp TYPE spta_t_after_rfc_exp
                     co_spta_gateway TYPE REF TO zcl_spta_gateway.

  CONSTANTS: lc_max_task_crash TYPE i VALUE 1.

  DATA: lv_result TYPE xstring,
        lo_result TYPE REF TO object,
        ls_objects_in_process LIKE LINE OF it_objects_in_process,
        lv_task_id TYPE guid_32,
        lv_tc_size TYPE i,
        lv_rc_size TYPE i.

  IF iv_rfcsubrc IS INITIAL.
*   Task completed successfully

    CALL FUNCTION 'SPTA_INDX_PACKAGE_DECODE'
      EXPORTING
        indxtab = it_rfcdata
      IMPORTING
        data    = lv_result.

    CALL TRANSFORMATION id_indent
    SOURCE XML lv_result
    RESULT obj = lo_result.

    co_spta_gateway->mo_results->add( lo_result ).

    lv_tc_size = co_spta_gateway->mo_tasks->size( ).
    lv_rc_size = co_spta_gateway->mo_results->size( ).
    zcl_spta_wrapper=>progress_indicator( iv_completed = lv_rc_size
                                          iv_total = lv_tc_size ).
  ELSE.

    READ TABLE it_objects_in_process INTO ls_objects_in_process INDEX 1.
    IF sy-subrc = 0.
      lv_task_id = ls_objects_in_process-obj_id.
      co_spta_gateway->mo_message_handler->add_message( iv_task_id = lv_task_id
                                                        iv_task_name = ''
                                                        iv_rfcsubrc = iv_rfcsubrc
                                                        iv_rfcmsg = iv_rfcmsg ).

      IF ls_objects_in_process-fail_count = lc_max_task_crash.
*       If the task has already crashed, and now it has crashed a second time,
*       we will not restart it
        cs_after_rfc_exp-no_resubmission_on_error = abap_true.
      ELSE.
        cs_after_rfc_exp-no_resubmission_on_error = co_spta_gateway->mv_no_resubmission_on_error.
      ENDIF.

    ENDIF.

  ENDIF.

ENDFORM.                    "after_rfc

*&---------------------------------------------------------------------*
*&      Form  process_failed_objects
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--CT_RFCDATA             text
*      <--CT_FAILED_OBJECTS      text
*      <--CT_OBJECTS_IN_PROCESS  text
*      <--CO_SPTA_GATEWAY        text
*----------------------------------------------------------------------*
FORM process_failed_objects CHANGING cs_before_rfc_exp TYPE spta_t_before_rfc_exp
                                     ct_rfcdata TYPE spta_t_indxtab
                                     ct_failed_objects TYPE spta_t_failed_objects
                                     ct_objects_in_process TYPE spta_t_objects_in_process
                                     co_spta_gateway TYPE REF TO zcl_spta_gateway.

  DATA: lo_tasks_iterator TYPE REF TO zif_iterator,
        lo_task TYPE REF TO zcl_abstract_task,
        lv_task TYPE xstring,
        ls_objects_in_process LIKE LINE OF ct_objects_in_process.

  FIELD-SYMBOLS: <lfs_failed_objects> LIKE LINE OF ct_failed_objects.

  READ TABLE ct_failed_objects ASSIGNING <lfs_failed_objects> INDEX 1.
  IF <lfs_failed_objects> IS ASSIGNED.

    lo_tasks_iterator = co_spta_gateway->mo_tasks->get_iterator( ).

    WHILE lo_tasks_iterator->has_next( ) = abap_true.
      lo_task ?= lo_tasks_iterator->next( ).

      IF lo_task->zif_task~get_id( ) = <lfs_failed_objects>-obj_id.

        lv_task = zcl_spta_wrapper=>serialize( lo_task ).

        CALL FUNCTION 'SPTA_INDX_PACKAGE_ENCODE'
          EXPORTING
            data    = lv_task
          IMPORTING
            indxtab = ct_rfcdata.

        ls_objects_in_process-obj_id = <lfs_failed_objects>-obj_id.
        ls_objects_in_process-fail_count = <lfs_failed_objects>-fail_count + 1.
        ls_objects_in_process-last_error = <lfs_failed_objects>-last_error.

        APPEND ls_objects_in_process TO ct_objects_in_process[].

        CLEAR: ct_failed_objects[], ct_failed_objects.
        cs_before_rfc_exp-start_rfc = abap_true.
        EXIT.
      ENDIF.

    ENDWHILE.

  ENDIF.

ENDFORM.                    "process_failed_objects
