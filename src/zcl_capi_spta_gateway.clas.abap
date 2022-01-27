CLASS zcl_capi_spta_gateway DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA mo_tasks TYPE REF TO zif_capi_collection .
    DATA mv_no_resubmission_on_error TYPE boole_d .
    DATA mo_capi_message_handler TYPE REF TO zif_capi_message_handler .
    DATA mo_results TYPE REF TO zif_capi_collection .
    DATA mo_tasks_iterator TYPE REF TO zif_capi_iterator .

    CLASS-METHODS serialize_result
      IMPORTING
        !io_result       TYPE REF TO if_serializable_object
      RETURNING
        VALUE(rv_result) TYPE xstring .
    CLASS-METHODS serialize_task
      IMPORTING
        !io_task         TYPE REF TO zif_capi_task
      RETURNING
        VALUE(rv_result) TYPE xstring .
    CLASS-METHODS deserialize_result
      IMPORTING
        !iv_result       TYPE xstring
      RETURNING
        VALUE(ro_result) TYPE REF TO if_serializable_object .
    CLASS-METHODS deserialize_task
      IMPORTING
        !iv_task         TYPE xstring
      RETURNING
        VALUE(ro_result) TYPE REF TO zif_capi_task .
    METHODS constructor
      IMPORTING
        !io_tasks                    TYPE REF TO zif_capi_collection
        !iv_no_resubmission_on_error TYPE boole_d
        !io_capi_message_handler     TYPE REF TO zif_capi_message_handler .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_SPTA_GATEWAY IMPLEMENTATION.


  METHOD constructor.

    mo_tasks = io_tasks.
    mo_tasks_iterator = mo_tasks->get_iterator( ).
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.
    mo_capi_message_handler = io_capi_message_handler.

    CREATE OBJECT mo_results TYPE zcl_capi_collection.

  ENDMETHOD.


  METHOD deserialize_result.

    CALL TRANSFORMATION id_indent
      SOURCE XML iv_result
      RESULT obj = ro_result.

  ENDMETHOD.


  METHOD deserialize_task.

    CALL TRANSFORMATION id_indent
      SOURCE XML iv_task
      RESULT obj = ro_result.

  ENDMETHOD.


  METHOD serialize_result.

    CALL TRANSFORMATION id_indent
      SOURCE obj = io_result
      RESULT XML rv_result.

  ENDMETHOD.


  METHOD serialize_task.

    CALL TRANSFORMATION id_indent
      SOURCE obj = io_task
      RESULT XML rv_result.

  ENDMETHOD.
ENDCLASS.
